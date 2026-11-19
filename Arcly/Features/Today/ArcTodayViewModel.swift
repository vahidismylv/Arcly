import Combine
import Foundation

final class ArcTodayViewModel {
    enum Phase: Equatable {
        case firstLaunch
        case resting
        case fasting
        case goalReached
    }

    struct Detail: Equatable {
        let title: String
        let value: String
        var isEditable = false
    }

    struct WeekDay: Equatable {
        let symbol: String
        let status: ArcDayStatus
        let isToday: Bool
        let isFuture: Bool
    }

    struct State: Equatable {
        var phase: Phase
        var dateText: String
        var protocolTitle: String
        var streakText: String?
        var timerMain: String
        var timerSeconds: String
        var timerAccessibilityLabel: String
        var statusTitle: String
        var statusDetail: String
        var horizonProgress: Double
        var details: [Detail]
        var week: [WeekDay]
        var weekAccessibilityValue: String
        var isFasting: Bool
    }

    @Published private(set) var state: State

    var goalReached: AnyPublisher<Void, Never> {
        goalReachedSubject.eraseToAnyPublisher()
    }

    var needsEndConfirmation: Bool {
        guard let fast = store.activeFast else { return false }
        return fast.duration(at: now()) < fast.targetDuration
    }

    var endConfirmationMessage: String {
        guard let fast = store.activeFast else { return "" }
        let elapsed = ArcDurationFormatter.short(fast.duration(at: now()))
        let target = ArcDurationFormatter.short(fast.targetDuration)
        return String(localized: "You've fasted \(elapsed) of your \(target) goal. It will be saved as ended early.")
    }

    var onShowSchedule: (() -> Void)?
    var onShowSettings: (() -> Void)?
    var onEditActiveFast: ((ArcFast.ID) -> Void)?

    private let store: ArcFastStore
    private let reminderScheduler: ArcReminderScheduler
    private let calendar: Calendar
    private let now: () -> Date
    private let goalReachedSubject = PassthroughSubject<Void, Never>()
    private var trackedGoal: (fastID: UUID, isReached: Bool)?
    private var storeCancellable: AnyCancellable?
    private var timerCancellable: AnyCancellable?

    init(
        store: ArcFastStore,
        reminderScheduler: ArcReminderScheduler,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.reminderScheduler = reminderScheduler
        self.calendar = calendar
        self.now = now
        state = Self.makeState(fasts: store.fasts, schedule: store.schedule, now: now(), calendar: calendar)

        // @Published emits before the store's property is assigned, so the emitted values are used directly.
        storeCancellable = store.$fasts
            .combineLatest(store.$schedule)
            .sink { [weak self] fasts, schedule in
                self?.refresh(fasts: fasts, schedule: schedule)
            }
    }

    func startUpdating() {
        refresh(fasts: store.fasts, schedule: store.schedule)
        timerCancellable = Timer.publish(every: 1, tolerance: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                refresh(fasts: store.fasts, schedule: store.schedule)
            }
    }

    func stopUpdating() {
        timerCancellable = nil
    }

    func startFast() {
        store.startFast(at: now())
        // Asked here rather than at launch: the user has just shown why reminders matter.
        Task { await reminderScheduler.requestAuthorizationIfNeeded() }
    }

    func endFast() {
        store.endActiveFast(at: now())
    }

    func showSchedule() {
        onShowSchedule?()
    }

    func showSettings() {
        onShowSettings?()
    }

    func editActiveFastStart() {
        guard let fast = store.activeFast else { return }
        onEditActiveFast?(fast.id)
    }

    // MARK: - State

    private func refresh(fasts: [ArcFast], schedule: ArcSchedule) {
        let newState = Self.makeState(fasts: fasts, schedule: schedule, now: now(), calendar: calendar)
        let activeFast = fasts.last { $0.isActive }
        let isReached = newState.phase == .goalReached

        // Fire only on the transition seen live, not when the screen opens on an already finished goal.
        if let activeFast, let trackedGoal, trackedGoal.fastID == activeFast.id, !trackedGoal.isReached, isReached {
            goalReachedSubject.send()
        }
        trackedGoal = activeFast.map { ($0.id, isReached) }

        if newState != state {
            state = newState
        }
    }

    private static func makeState(fasts: [ArcFast], schedule: ArcSchedule, now: Date, calendar: Calendar) -> State {
        let activeFast = fasts.last { $0.isActive }
        let lastFinished = fasts.filter { !$0.isActive }.max { ($0.endDate ?? $0.startDate) < ($1.endDate ?? $1.startDate) }
        let streak = ArcStreakCalculator(calendar: calendar).currentStreak(in: fasts, now: now)
        let (week, weekDescription) = self.week(for: fasts, now: now, calendar: calendar)

        var state = State(
            phase: .firstLaunch,
            dateText: now.formatted(.dateTime.day().month(.wide)).uppercased(),
            protocolTitle: schedule.fastingProtocol.title,
            streakText: streak > 0 ? String(localized: "\(streak) days in a row") : nil,
            timerMain: "",
            timerSeconds: "",
            timerAccessibilityLabel: "",
            statusTitle: "",
            statusDetail: "",
            horizonProgress: 0,
            details: [],
            week: week,
            weekAccessibilityValue: weekDescription,
            isFasting: activeFast != nil
        )

        if let activeFast {
            applyFasting(activeFast, to: &state, now: now, calendar: calendar)
        } else if let lastFinished, let endDate = lastFinished.endDate {
            applyResting(after: lastFinished, endedAt: endDate, schedule: schedule, to: &state, now: now, calendar: calendar)
        } else {
            applyFirstLaunch(schedule: schedule, to: &state)
        }
        return state
    }

    private static func applyFasting(_ fast: ArcFast, to state: inout State, now: Date, calendar: Calendar) {
        let elapsed = fast.duration(at: now)
        let remaining = fast.targetDuration - elapsed
        let isGoalReached = remaining <= 0

        state.phase = isGoalReached ? .goalReached : .fasting
        setTimer(elapsed, on: &state)
        state.timerAccessibilityLabel = String(
            localized: "\(ArcDurationFormatter.spoken(elapsed)) of \(ArcDurationFormatter.spoken(fast.targetDuration))"
        )
        state.horizonProgress = min(elapsed / fast.targetDuration, 1)

        if isGoalReached {
            state.statusTitle = String(localized: "Goal reached")
            state.statusDetail = -remaining < 60
                ? String(localized: "End your fast whenever you're ready")
                : String(localized: "\(ArcDurationFormatter.short(-remaining)) past your goal")
        } else {
            state.statusTitle = String(localized: "hours fasted")
            state.statusDetail = String(localized: "\(ArcDurationFormatter.short(remaining, roundingUp: true)) to goal")
        }

        // The goal comes from the fast's own snapshot, so schedule edits never move it.
        state.details = [
            Detail(
                title: String(localized: "Started"),
                value: ArcDateFormatter.relativeDayAndTime(fast.startDate, now: now, calendar: calendar),
                isEditable: true
            ),
            Detail(title: String(localized: "Goal"), value: ArcDateFormatter.relativeDayAndTime(fast.goalDate, now: now, calendar: calendar))
        ]
    }

    private static func applyResting(
        after fast: ArcFast,
        endedAt endDate: Date,
        schedule: ArcSchedule,
        to state: inout State,
        now: Date,
        calendar: Calendar
    ) {
        let sinceLastFast = max(0, now.timeIntervalSince(endDate))
        state.phase = .resting
        setTimer(sinceLastFast, on: &state)
        state.timerAccessibilityLabel = String(localized: "\(ArcDurationFormatter.spoken(sinceLastFast)) since your last fast")
        state.statusTitle = String(localized: "since your last fast")

        if let nextStart = nextScheduledStart(for: schedule, after: now, calendar: calendar) {
            let when = ArcDateFormatter.relativeDayAndTime(nextStart, now: now, calendar: calendar)
            state.statusDetail = String(localized: "Next fast: \(when)")
        }

        state.details = [
            Detail(title: String(localized: "Last fast"), value: ArcDurationFormatter.short(fast.duration(at: now))),
            Detail(title: String(localized: "Ended"), value: ArcDateFormatter.relativeDayAndTime(endDate, now: now, calendar: calendar))
        ]
    }

    private static func applyFirstLaunch(schedule: ArcSchedule, to state: inout State) {
        state.phase = .firstLaunch
        setTimer(0, on: &state)
        state.timerAccessibilityLabel = String(localized: "No fast yet")
        state.statusTitle = String(localized: "Ready when you are")
        state.statusDetail = String(localized: "Your goal: \(ArcDurationFormatter.short(schedule.fastingProtocol.fastingDuration))")
    }

    private static func setTimer(_ interval: TimeInterval, on state: inout State) {
        let parts = ArcDurationFormatter.clockParts(interval)
        state.timerMain = parts.hoursAndMinutes
        state.timerSeconds = parts.seconds
    }

    private static func nextScheduledStart(for schedule: ArcSchedule, after now: Date, calendar: Calendar) -> Date? {
        let components = DateComponents(hour: schedule.fastingStartTime.hour, minute: schedule.fastingStartTime.minute)
        return calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)
    }

    // MARK: - Week

    private static func week(for fasts: [ArcFast], now: Date, calendar: Calendar) -> ([WeekDay], String) {
        let activity = ArcDailyActivity(calendar: calendar)
        let today = calendar.startOfDay(for: now)
        var descriptions: [String] = []

        let days = activity.week(containing: now).map { day -> WeekDay in
            let weekdayIndex = calendar.component(.weekday, from: day) - 1
            let status = activity.status(on: day, in: fasts)
            let isFuture = day > today
            if !isFuture {
                let name = calendar.standaloneWeekdaySymbols[weekdayIndex]
                descriptions.append(String(localized: "\(name): \(statusDescription(status))"))
            }
            return WeekDay(
                symbol: calendar.veryShortStandaloneWeekdaySymbols[weekdayIndex],
                status: status,
                isToday: day == today,
                isFuture: isFuture
            )
        }
        return (days, descriptions.joined(separator: ", "))
    }

    private static func statusDescription(_ status: ArcDayStatus) -> String {
        switch status {
        case .none: String(localized: "no fast")
        case .active: String(localized: "fasting now")
        case .completed: String(localized: "goal reached")
        case .endedEarly: String(localized: "ended early")
        }
    }
}
