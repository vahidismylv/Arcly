import Foundation

nonisolated enum ArcDayStatus: Equatable {
    case none
    case active
    case completed
    case endedEarly
}

/// Groups fasts by calendar day for the History calendar and the weekly summary on Today.
/// A fast always belongs to the day it started on, even when it ends after midnight.
nonisolated struct ArcDailyActivity {
    let calendar: Calendar

    func fasts(startingOn day: Date, in fasts: [ArcFast]) -> [ArcFast] {
        fasts
            .filter { calendar.isDate($0.startDate, inSameDayAs: day) }
            .sorted { $0.startDate > $1.startDate }
    }

    /// The most meaningful outcome of the day: a reached goal outranks a running fast, which outranks an early end.
    func status(on day: Date, in fasts: [ArcFast]) -> ArcDayStatus {
        let statuses = self.fasts(startingOn: day, in: fasts).map(\.status)
        if statuses.contains(.completed) { return .completed }
        if statuses.contains(.active) { return .active }
        if statuses.contains(.endedEarly) { return .endedEarly }
        return .none
    }

    /// The seven days of the week containing `date`, starting on the locale's first weekday.
    func week(containing date: Date) -> [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    /// The days of the month containing `date`, padded with `nil` so the first day lands under its weekday.
    func monthGrid(containing date: Date) -> [Date?] {
        guard
            let month = calendar.dateInterval(of: .month, for: date),
            let dayCount = calendar.range(of: .day, in: .month, for: date)?.count
        else { return [] }

        let leadingBlanks = (calendar.component(.weekday, from: month.start) - calendar.firstWeekday + 7) % 7
        let days: [Date?] = (0..<dayCount).map { calendar.date(byAdding: .day, value: $0, to: month.start) }
        let trailingBlanks = (7 - (leadingBlanks + dayCount) % 7) % 7
        return Array(repeating: nil, count: leadingBlanks) + days + Array(repeating: nil, count: trailingBlanks)
    }

    /// Weekday symbols ordered to match `week(containing:)` and `monthGrid(containing:)`.
    func orderedWeekdaySymbols(_ symbols: [String]) -> [String] {
        guard symbols.count == 7 else { return symbols }
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }
}
