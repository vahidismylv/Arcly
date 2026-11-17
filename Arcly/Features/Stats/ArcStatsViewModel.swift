import Combine
import Foundation

final class ArcStatsViewModel {
    enum Range: Int, CaseIterable {
        case week = 7
        case month = 30

        var title: String {
            switch self {
            case .week: String(localized: "7 days")
            case .month: String(localized: "30 days")
            }
        }
    }

    struct Weight: Equatable {
        let latest: String?
        let lastEntry: String?
        let change: String?
        let chartValues: [Double]
        let emptyMessage: String?
        let buttonTitle: String
        let accessibilityValue: String
    }

    struct State: Equatable {
        var range: Range
        var sessionsValue: String
        var averageValue: String
        var averageAccessibilityValue: String
        var chart: ArcBarChartModel
        var chartCaption: String
        var chartAccessibilityValue: String
        var bestStreakValue: String
        var weight: Weight?
    }

    @Published private(set) var state: State

    var onLogWeight: (() -> Void)?

    private let store: ArcFastStore
    private let calculator: ArcStatsCalculator
    private let streaks: ArcStreakCalculator
    private let now: () -> Date
    private var range = Range.week
    private var cancellable: AnyCancellable?

    init(store: ArcFastStore, calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.calculator = ArcStatsCalculator(calendar: calendar)
        self.streaks = ArcStreakCalculator(calendar: calendar)
        self.now = now
        state = Self.makeState(
            fasts: store.fasts,
            weightEntries: store.weightEntries,
            preferences: store.preferences,
            range: .week,
            calculator: calculator,
            streaks: streaks,
            now: now()
        )

        // @Published emits before the store's properties are assigned, so the emitted values are used directly.
        cancellable = Publishers.CombineLatest3(store.$fasts, store.$weightEntries, store.$preferences)
            .dropFirst()
            .sink { [weak self] fasts, weightEntries, preferences in
                self?.update(fasts: fasts, weightEntries: weightEntries, preferences: preferences)
            }
    }

    func refresh() {
        update(fasts: store.fasts, weightEntries: store.weightEntries, preferences: store.preferences)
    }

    func selectRange(_ range: Range) {
        self.range = range
        refresh()
    }

    func logWeight() {
        onLogWeight?()
    }

    // MARK: - State

    private func update(fasts: [ArcFast], weightEntries: [ArcWeightEntry], preferences: ArcPreferences) {
        let newState = Self.makeState(
            fasts: fasts,
            weightEntries: weightEntries,
            preferences: preferences,
            range: range,
            calculator: calculator,
            streaks: streaks,
            now: now()
        )
        if newState != state {
            state = newState
        }
    }

    private static func makeState(
        fasts: [ArcFast],
        weightEntries: [ArcWeightEntry],
        preferences: ArcPreferences,
        range: Range,
        calculator: ArcStatsCalculator,
        streaks: ArcStreakCalculator,
        now: Date
    ) -> State {
        let summary = calculator.periodSummary(for: fasts, days: range.rawValue, now: now)
        let days = calculator.dailyFasts(for: fasts, days: range.rawValue, now: now)
        let chart = chart(from: days, range: range)
        let bestStreak = streaks.bestStreak(in: fasts)

        return State(
            range: range,
            sessionsValue: summary.sessionCount.formatted(),
            averageValue: summary.averageDuration.map { ArcDurationFormatter.short($0) } ?? "—",
            averageAccessibilityValue: summary.averageDuration.map { ArcDurationFormatter.spoken($0) }
                ?? String(localized: "No finished fasts yet"),
            chart: chart,
            chartCaption: chartCaption(for: days, hasSharedGoal: chart.goalLine != nil),
            chartAccessibilityValue: chartSummary(for: days),
            bestStreakValue: String(localized: "\(bestStreak) days"),
            weight: preferences.isWeightLogEnabled
                ? weight(
                    from: calculator.weightTrend(for: weightEntries, days: range.rawValue, now: now),
                    unit: preferences.weightUnit,
                    range: range
                )
                : nil
        )
    }

    // MARK: - Chart

    private static func chart(from days: [ArcDailyFast], range: Range) -> ArcBarChartModel {
        let hour: TimeInterval = 3600
        let bars = days.enumerated().map { index, day in
            ArcBarChartModel.Bar(
                value: (day.duration ?? 0) / hour,
                goal: day.targetDuration.map { $0 / hour },
                isGoalReached: day.reachedGoal,
                label: axisLabel(for: day.day, index: index, count: days.count, range: range)
            )
        }

        // A single dashed goal line is only honest when every fast in the period shared the same goal.
        let goals = Set(days.compactMap(\.targetDuration))
        let sharedGoal = goals.count == 1 ? goals.first : nil
        return ArcBarChartModel(
            bars: bars,
            goalLine: sharedGoal.map { $0 / hour },
            goalLabel: sharedGoal.map { ArcDurationFormatter.short($0) }
        )
    }

    // Seven bars have room for every weekday; thirty only for a date roughly once a week, ending on today.
    private static func axisLabel(for day: Date, index: Int, count: Int, range: Range) -> String? {
        switch range {
        case .week:
            return day.formatted(.dateTime.weekday(.narrow))
        case .month:
            return (count - 1 - index).isMultiple(of: 7) ? day.formatted(.dateTime.day()) : nil
        }
    }

    private static func chartCaption(for days: [ArcDailyFast], hasSharedGoal: Bool) -> String {
        guard days.contains(where: { $0.duration != nil }) else {
            return String(localized: "No finished fasts in this period yet.")
        }
        let rule = String(localized: "Each bar is the longest finished fast that started that day.")
        guard !hasSharedGoal else { return rule }
        return rule + " " + String(localized: "Marks show each fast's own goal.")
    }

    private static func chartSummary(for days: [ArcDailyFast]) -> String {
        let fastingDays = days.compactMap(\.duration)
        guard !fastingDays.isEmpty else { return String(localized: "No finished fasts in this period") }
        let average = fastingDays.reduce(0, +) / Double(fastingDays.count)
        let reached = days.filter(\.reachedGoal).count
        return String(localized: "Average \(ArcDurationFormatter.spoken(average)). Goal reached on \(reached) of \(fastingDays.count) days with a fast.")
    }

    // MARK: - Weight

    // Weight is reported neutrally: a change is a fact, not a success or a failure.
    private static func weight(from trend: ArcWeightTrend, unit: ArcWeightUnit, range: Range) -> Weight {
        guard let latest = trend.latest else {
            return Weight(
                latest: nil,
                lastEntry: nil,
                change: nil,
                chartValues: [],
                emptyMessage: String(localized: "Log your first weight to see how it changes over time."),
                buttonTitle: String(localized: "Log first weight"),
                accessibilityValue: String(localized: "No entries yet")
            )
        }

        let latestText = ArcWeightFormatter.weight(kilograms: latest.kilograms, unit: unit)
        let lastEntry = String(localized: "Last entry · \(ArcDateFormatter.shortDay(latest.date))")
        let change = trend.change.map {
            String(localized: "\(ArcWeightFormatter.change(kilograms: $0, unit: unit)) over \(range.title)")
        }
        return Weight(
            latest: latestText,
            lastEntry: lastEntry,
            change: change,
            chartValues: trend.entries.map { unit.value(fromKilograms: $0.kilograms) },
            emptyMessage: nil,
            buttonTitle: String(localized: "Log"),
            accessibilityValue: [latestText, lastEntry, change].compactMap { $0 }.joined(separator: ", ")
        )
    }
}
