import Foundation

nonisolated struct ArcStreakCalculator {
    let calendar: Calendar

    // Today without a completed fast doesn't break the streak yet: the user still has the rest of the day.
    func currentStreak(in fasts: [ArcFast], now: Date) -> Int {
        let days = completedDays(in: fasts)
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }

        var day = days.contains(today) ? today : yesterday
        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    func bestStreak(in fasts: [ArcFast]) -> Int {
        var best = 0
        var current = 0
        var previousDay: Date?
        for day in completedDays(in: fasts).sorted() {
            let isConsecutive = previousDay.flatMap { calendar.date(byAdding: .day, value: 1, to: $0) } == day
            current = isConsecutive ? current + 1 : 1
            best = max(best, current)
            previousDay = day
        }
        return best
    }

    private func completedDays(in fasts: [ArcFast]) -> Set<Date> {
        Set(
            fasts
                .filter { $0.status == .completed }
                .compactMap(\.endDate)
                .map { calendar.startOfDay(for: $0) }
        )
    }
}
