import Combine
import Foundation

final class ArcHistoryViewModel {
    struct CalendarDay: Equatable {
        let date: Date
        let number: String
        let status: ArcDayStatus
        let isSelected: Bool
        let isToday: Bool
        let isFuture: Bool
        let accessibilityLabel: String
    }

    struct Session: Equatable {
        let id: ArcFast.ID
        let duration: String
        let timeRange: String
        let status: ArcFastStatus
        let statusText: String
        let accessibilityLabel: String
    }

    struct State: Equatable {
        var monthTitle: String
        var canShowNextMonth: Bool
        var weekdaySymbols: [String]
        var days: [CalendarDay?]
        var selectedDayTitle: String
        var sessions: [Session]
        var emptyMessage: String
    }

    @Published private(set) var state: State

    var onEditFast: ((ArcFast.ID) -> Void)?

    private let store: ArcFastStore
    private let calendar: Calendar
    private let activity: ArcDailyActivity
    private let now: () -> Date
    private var displayedMonth: Date
    private var selectedDay: Date
    private var cancellable: AnyCancellable?

    init(store: ArcFastStore, calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.calendar = calendar
        self.activity = ArcDailyActivity(calendar: calendar)
        self.now = now
        let today = calendar.startOfDay(for: now())
        selectedDay = today
        displayedMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        state = Self.makeState(
            fasts: store.fasts,
            displayedMonth: displayedMonth,
            selectedDay: selectedDay,
            activity: activity,
            calendar: calendar,
            now: now()
        )
        cancellable = store.$fasts.dropFirst().sink { [weak self] fasts in
            self?.rebuild(fasts: fasts)
        }
    }

    // Running fasts show elapsed time, and "today" moves at midnight, so the list is refreshed on appear.
    func refresh() {
        rebuild(fasts: store.fasts)
    }

    func showPreviousMonth() {
        moveMonth(by: -1)
    }

    func showNextMonth() {
        guard state.canShowNextMonth else { return }
        moveMonth(by: 1)
    }

    func select(day: Date) {
        let day = calendar.startOfDay(for: day)
        guard day <= calendar.startOfDay(for: now()) else { return }
        selectedDay = day
        rebuild(fasts: store.fasts)
    }

    func editFast(id: ArcFast.ID) {
        onEditFast?(id)
    }

    func deleteFast(id: ArcFast.ID) {
        store.deleteFast(id: id)
    }

    // MARK: - State

    private func moveMonth(by value: Int) {
        guard let month = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = month
        rebuild(fasts: store.fasts)
    }

    private func rebuild(fasts: [ArcFast]) {
        let newState = Self.makeState(
            fasts: fasts,
            displayedMonth: displayedMonth,
            selectedDay: selectedDay,
            activity: activity,
            calendar: calendar,
            now: now()
        )
        if newState != state {
            state = newState
        }
    }

    private static func makeState(
        fasts: [ArcFast],
        displayedMonth: Date,
        selectedDay: Date,
        activity: ArcDailyActivity,
        calendar: Calendar,
        now: Date
    ) -> State {
        let today = calendar.startOfDay(for: now)
        let currentMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today

        let days = activity.monthGrid(containing: displayedMonth).map { date -> CalendarDay? in
            guard let date else { return nil }
            return calendarDay(
                for: date,
                status: activity.status(on: date, in: fasts),
                selectedDay: selectedDay,
                today: today
            )
        }

        let sessions = activity.fasts(startingOn: selectedDay, in: fasts).map {
            session(for: $0, calendar: calendar, now: now)
        }

        return State(
            monthTitle: displayedMonth.formatted(.dateTime.month(.wide).year()),
            canShowNextMonth: displayedMonth < currentMonth,
            weekdaySymbols: activity.orderedWeekdaySymbols(calendar.veryShortStandaloneWeekdaySymbols),
            days: days,
            selectedDayTitle: ArcDateFormatter.longDay(selectedDay),
            sessions: sessions,
            emptyMessage: fasts.isEmpty
                ? String(localized: "Your sessions will appear here after your first fast.")
                : String(localized: "No sessions started on this day.")
        )
    }

    private static func calendarDay(for date: Date, status: ArcDayStatus, selectedDay: Date, today: Date) -> CalendarDay {
        let isSelected = date == selectedDay
        var parts = [ArcDateFormatter.longDay(date)]
        switch status {
        case .completed: parts.append(String(localized: "goal reached"))
        case .endedEarly: parts.append(String(localized: "ended early"))
        case .active: parts.append(String(localized: "fasting now"))
        case .none: break
        }

        return CalendarDay(
            date: date,
            number: date.formatted(.dateTime.day()),
            status: status,
            isSelected: isSelected,
            isToday: date == today,
            isFuture: date > today,
            accessibilityLabel: parts.joined(separator: ", ")
        )
    }

    private static func session(for fast: ArcFast, calendar: Calendar, now: Date) -> Session {
        let duration = ArcDurationFormatter.short(fast.duration(at: now))
        let statusText = switch fast.status {
        case .active: String(localized: "In progress")
        case .completed: String(localized: "Goal reached")
        case .endedEarly: String(localized: "Ended early")
        }

        let start = ArcDateFormatter.time(fast.startDate)
        let timeRange: String
        if let endDate = fast.endDate {
            let end = ArcDateFormatter.time(endDate)
            if calendar.isDate(endDate, inSameDayAs: fast.startDate) {
                timeRange = "\(start) – \(end)"
            } else {
                // The day is already in the section title, but crossing midnight needs both dates spelled out.
                let startDay = fast.startDate.formatted(.dateTime.day().month(.abbreviated))
                let endDay = endDate.formatted(.dateTime.day().month(.abbreviated))
                timeRange = "\(startDay), \(start) – \(endDay), \(end)"
            }
        } else {
            timeRange = String(localized: "Since \(start)")
        }

        let goal = ArcDurationFormatter.short(fast.targetDuration)
        return Session(
            id: fast.id,
            duration: duration,
            timeRange: timeRange,
            status: fast.status,
            statusText: statusText,
            accessibilityLabel: String(localized: "\(duration) of \(goal) goal, \(timeRange), \(statusText)")
        )
    }
}
