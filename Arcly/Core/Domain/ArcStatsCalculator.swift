import Foundation

nonisolated struct ArcPeriodSummary: Equatable {
    let sessionCount: Int
    let averageDuration: TimeInterval?
}

nonisolated struct ArcDailyFast: Equatable {
    let day: Date
    /// The longest finished fast that started on this day, if any.
    let duration: TimeInterval?
    /// That fast's own goal, taken from its protocol snapshot.
    let targetDuration: TimeInterval?

    var reachedGoal: Bool {
        guard let duration, let targetDuration else { return false }
        return duration >= targetDuration
    }
}

nonisolated struct ArcWeightTrend: Equatable {
    let latest: ArcWeightEntry?
    /// Entries inside the requested window, oldest first.
    let entries: [ArcWeightEntry]
    /// Kilograms gained (positive) or lost (negative) across the window.
    let change: Double?
}

/// Period figures for Progress. A period is the last `days` calendar days including today,
/// and a fast belongs to the day it started on, like in History. A running fast has no
/// final duration yet, so only finished fasts are counted.
nonisolated struct ArcStatsCalculator {
    let calendar: Calendar

    func periodSummary(for fasts: [ArcFast], days: Int, now: Date) -> ArcPeriodSummary {
        let durations = finishedFasts(in: fasts, days: days, now: now).map { $0.duration(at: now) }
        return ArcPeriodSummary(
            sessionCount: durations.count,
            averageDuration: durations.isEmpty ? nil : durations.reduce(0, +) / Double(durations.count)
        )
    }

    /// One entry per calendar day, oldest first, ending today.
    func dailyFasts(for fasts: [ArcFast], days: Int, now: Date) -> [ArcDailyFast] {
        let longestByDay = finishedFasts(in: fasts, days: days, now: now).reduce(into: [Date: ArcFast]()) { longest, fast in
            let day = calendar.startOfDay(for: fast.startDate)
            if let current = longest[day], current.duration(at: now) >= fast.duration(at: now) { return }
            longest[day] = fast
        }

        return windowDays(days: days, now: now).map { day in
            let fast = longestByDay[day]
            return ArcDailyFast(day: day, duration: fast?.duration(at: now), targetDuration: fast?.targetDuration)
        }
    }

    func weightTrend(for entries: [ArcWeightEntry], days: Int, now: Date) -> ArcWeightTrend {
        let chronological = entries.sorted { $0.date < $1.date }
        let start = windowStart(days: days, now: now)
        let inWindow = chronological.filter { $0.date >= start && $0.date <= now }

        var change: Double?
        if let first = inWindow.first, let last = inWindow.last, inWindow.count > 1 {
            change = last.kilograms - first.kilograms
        }
        return ArcWeightTrend(latest: chronological.last, entries: inWindow, change: change)
    }

    // MARK: - Window

    private func finishedFasts(in fasts: [ArcFast], days: Int, now: Date) -> [ArcFast] {
        let start = windowStart(days: days, now: now)
        return fasts.filter { !$0.isActive && $0.startDate >= start && $0.startDate <= now }
    }

    private func windowStart(days: Int, now: Date) -> Date {
        let today = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: -(max(days, 1) - 1), to: today) ?? today
    }

    private func windowDays(days: Int, now: Date) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0..<max(days, 1)).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }
}
