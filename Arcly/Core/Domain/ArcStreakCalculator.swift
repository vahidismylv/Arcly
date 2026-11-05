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

    private func completedDays(in fasts: [ArcFast]) -> Set<Date> {
        Set(
            fasts
                .filter { $0.status == .completed }
                .compactMap(\.endDate)
                .map { calendar.startOfDay(for: $0) }
        )
    }
}
