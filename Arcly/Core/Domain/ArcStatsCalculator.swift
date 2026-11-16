import Foundation

nonisolated struct ArcFastStatistics: Equatable {
    let totalFasts: Int
    let averageDuration: TimeInterval?
    let longestDuration: TimeInterval?
    let currentStreak: Int
    let bestStreak: Int
    /// Share of finished fasts that reached their goal, 0...1.
    let completionRate: Double?
}

nonisolated struct ArcDailyDuration: Equatable {
    let day: Date
    let duration: TimeInterval
}

nonisolated struct ArcWeightTrend: Equatable {
    let latest: ArcWeightEntry?
    /// Entries inside the requested window, oldest first.
    let entries: [ArcWeightEntry]
    /// Kilograms gained (positive) or lost (negative) across the window.
    let change: Double?
}

nonisolated struct ArcStatsCalculator {
    let calendar: Calendar

    // A running fast has no final duration yet, so only finished fasts count towards the numbers.
    func statistics(for fasts: [ArcFast], now: Date) -> ArcFastStatistics {
        let finished = fasts.filter { !$0.isActive }
        let durations = finished.map { $0.duration(at: now) }
        let completedCount = finished.filter { $0.status == .completed }.count
        let streaks = ArcStreakCalculator(calendar: calendar)

        return ArcFastStatistics(
            totalFasts: finished.count,
            averageDuration: durations.isEmpty ? nil : durations.reduce(0, +) / Double(durations.count),
            longestDuration: durations.max(),
            currentStreak: streaks.currentStreak(in: fasts, now: now),
            bestStreak: streaks.bestStreak(in: fasts),
            completionRate: finished.isEmpty ? nil : Double(completedCount) / Double(finished.count)
        )
    }

    /// One entry per calendar day, oldest first, ending today. A fast belongs to the day it ended,
    /// matching how streaks are counted.
    func dailyDurations(for fasts: [ArcFast], days: Int, now: Date) -> [ArcDailyDuration] {
        let today = calendar.startOfDay(for: now)
        let totals = fasts.reduce(into: [Date: TimeInterval]()) { totals, fast in
            guard let endDate = fast.endDate else { return }
            totals[calendar.startOfDay(for: endDate), default: 0] += fast.duration(at: now)
        }

        return (0..<max(days, 0)).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return ArcDailyDuration(day: day, duration: totals[day] ?? 0)
        }
    }

    func weightTrend(for entries: [ArcWeightEntry], days: Int, now: Date) -> ArcWeightTrend {
        let chronological = entries.sorted { $0.date < $1.date }
        let today = calendar.startOfDay(for: now)
        let windowStart = calendar.date(byAdding: .day, value: -(max(days, 1) - 1), to: today) ?? today
        let inWindow = chronological.filter { $0.date >= windowStart && $0.date <= now }

        var change: Double?
        if let first = inWindow.first, let last = inWindow.last, inWindow.count > 1 {
            change = last.kilograms - first.kilograms
        }
        return ArcWeightTrend(latest: chronological.last, entries: inWindow, change: change)
    }
}
