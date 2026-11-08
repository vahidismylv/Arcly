import Combine
import Foundation

final class ArcTodayViewModel {
    struct State: Equatable {
        var dial: ArcDialModel
        var isFasting: Bool
        var protocolTitle: String
        var streakTitle: String
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

    func showSchedule() {
        onShowSchedule?()
    }

    func endFast() {
        store.endActiveFast(at: now())
    }

    // MARK: - State

    private func refresh(fasts: [ArcFast], schedule: ArcSchedule) {
        let newState = Self.makeState(fasts: fasts, schedule: schedule, now: now(), calendar: calendar)
        let activeFast = fasts.last { $0.isActive }

        // Fire only on the transition seen live, not when the screen opens on an already finished goal.
        if let activeFast, let trackedGoal, trackedGoal.fastID == activeFast.id,
           !trackedGoal.isReached, newState.dial.isGoalReached {
            goalReachedSubject.send()
        }
        trackedGoal = activeFast.map { ($0.id, newState.dial.isGoalReached) }

        if newState != state {
            state = newState
        }
    }

    private static func makeState(fasts: [ArcFast], schedule: ArcSchedule, now: Date, calendar: Calendar) -> State {
        let activeFast = fasts.last { $0.isActive }
        let streak = ArcStreakCalculator(calendar: calendar).currentStreak(in: fasts, now: now)
        let dial = activeFast.map { fastingDial(for: $0, schedule: schedule, now: now, calendar: calendar) }
            ?? idleDial(lastEndDate: fasts.compactMap(\.endDate).max(), schedule: schedule, now: now, calendar: calendar)

        return State(
            dial: dial,
            isFasting: activeFast != nil,
            protocolTitle: schedule.fastingProtocol.title,
            streakTitle: String(localized: "\(streak) day streak")
        )
    }

    private static func fastingDial(for fast: ArcFast, schedule: ArcSchedule, now: Date, calendar: Calendar) -> ArcDialModel {
        let elapsed = fast.duration(at: now)
        let remaining = fast.targetDuration - elapsed
        let isGoalReached = remaining <= 0
        let spokenElapsed = ArcDurationFormatter.spoken(elapsed)
        let spokenTarget = ArcDurationFormatter.spoken(fast.targetDuration)

        return ArcDialModel(
            fastingWindowStart: windowStart(of: schedule),
            fastingWindowLength: windowLength(of: schedule),
            currentTime: dayFraction(of: now, calendar: calendar),
            progress: elapsed / fast.targetDuration,
            isGoalReached: isGoalReached,
            phase: String(localized: "Fasting"),
            elapsed: ArcDurationFormatter.clock(elapsed),
            detail: isGoalReached
                ? String(localized: "Goal reached")
                : String(localized: "\(ArcDurationFormatter.short(remaining, roundingUp: true)) to goal"),
            accessibilityValue: String(localized: "\(spokenElapsed) of \(spokenTarget)")
        )
    }

    private static func idleDial(lastEndDate: Date?, schedule: ArcSchedule, now: Date, calendar: Calendar) -> ArcDialModel {
        let sinceLastFast = lastEndDate.map { now.timeIntervalSince($0) } ?? 0
        let detail: String
        let accessibilityValue: String
        if lastEndDate != nil {
            detail = String(localized: "since last fast")
            accessibilityValue = String(localized: "\(ArcDurationFormatter.spoken(sinceLastFast)) since last fast")
        } else {
            detail = String(localized: "Start your first fast")
            accessibilityValue = String(localized: "No fast in progress")
        }

        return ArcDialModel(
            fastingWindowStart: windowStart(of: schedule),
            fastingWindowLength: windowLength(of: schedule),
            currentTime: dayFraction(of: now, calendar: calendar),
            progress: 0,
            isGoalReached: false,
            phase: String(localized: "Eating window"),
            elapsed: ArcDurationFormatter.clock(sinceLastFast),
            detail: detail,
            accessibilityValue: accessibilityValue
        )
    }

    private static func windowStart(of schedule: ArcSchedule) -> Double {
        Double(schedule.fastingStartTime.minutesSinceMidnight) / (24 * 60)
    }

    private static func windowLength(of schedule: ArcSchedule) -> Double {
        Double(schedule.fastingProtocol.fastingHours) / 24
    }

    // Wall-clock position in the current time zone, so the marker follows the user across zones.
    private static func dayFraction(of date: Date, calendar: Calendar) -> Double {
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        let seconds = (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0)
        return Double(seconds) / (24 * 3600)
    }
}
