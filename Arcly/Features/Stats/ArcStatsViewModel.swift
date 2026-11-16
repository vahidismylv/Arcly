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

    struct Metric: Equatable {
        let title: String
        let value: String
        let accessibilityValue: String?
    }

    struct Weight: Equatable {
        struct Entry: Equatable {
            let date: String
            let value: String
        }

        let latest: String
        let change: String?
        let chartValues: [Double]
        let recentEntries: [Entry]
    }

    struct State: Equatable {
        var range: Range
        var metrics: [Metric]
        var chart: ArcBarChartModel
        var chartAccessibilityValue: String
        var weight: Weight?
    }

    @Published private(set) var state: State

    var onLogWeight: (() -> Void)?

    private let store: ArcFastStore
    private let calculator: ArcStatsCalculator
    private let now: () -> Date
    private var range = Range.week
    private var cancellable: AnyCancellable?

    init(store: ArcFastStore, calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.calculator = ArcStatsCalculator(calendar: calendar)
        self.now = now
        state = Self.makeState(
            fasts: store.fasts,
            schedule: store.schedule,
            weightEntries: store.weightEntries,
            preferences: store.preferences,
            range: .week,
            calculator: calculator,
            now: now()
        )

        // @Published emits before the store's properties are assigned, so the emitted values are used directly.
        cancellable = Publishers.CombineLatest4(store.$fasts, store.$schedule, store.$weightEntries, store.$preferences)
            .dropFirst()
            .sink { [weak self] fasts, schedule, weightEntries, preferences in
                self?.update(fasts: fasts, schedule: schedule, weightEntries: weightEntries, preferences: preferences)
            }
    }

    func refresh() {
        update(fasts: store.fasts, schedule: store.schedule, weightEntries: store.weightEntries, preferences: store.preferences)
    }

    func selectRange(_ range: Range) {
        self.range = range
        refresh()
    }

    func logWeight() {
        onLogWeight?()
    }

    // MARK: - State

    private func update(fasts: [ArcFast], schedule: ArcSchedule, weightEntries: [ArcWeightEntry], preferences: ArcPreferences) {
        let newState = Self.makeState(
            fasts: fasts,
            schedule: schedule,
            weightEntries: weightEntries,
            preferences: preferences,
            range: range,
            calculator: calculator,
            now: now()
        )
        if newState != state {
            state = newState
        }
    }

    private static func makeState(
        fasts: [ArcFast],
        schedule: ArcSchedule,
        weightEntries: [ArcWeightEntry],
        preferences: ArcPreferences,
        range: Range,
        calculator: ArcStatsCalculator,
        now: Date
    ) -> State {
        let statistics = calculator.statistics(for: fasts, now: now)
        let days = calculator.dailyDurations(for: fasts, days: range.rawValue, now: now)
        let goal = schedule.fastingProtocol.fastingDuration

        return State(
            range: range,
            metrics: metrics(from: statistics),
            chart: chart(from: days, goal: goal, range: range),
            chartAccessibilityValue: chartSummary(for: days, goal: goal),
            weight: preferences.isWeightLogEnabled
                ? weight(from: calculator.weightTrend(for: weightEntries, days: range.rawValue, now: now), unit: preferences.weightUnit)
                : nil
        )
    }

    private static func metrics(from statistics: ArcFastStatistics) -> [Metric] {
        let placeholder = "—"
        let noData = String(localized: "No data yet")
        return [
            Metric(title: String(localized: "Total fasts"), value: statistics.totalFasts.formatted(), accessibilityValue: nil),
            Metric(
                title: String(localized: "Average"),
                value: statistics.averageDuration.map { ArcDurationFormatter.short($0) } ?? placeholder,
                accessibilityValue: statistics.averageDuration.map { ArcDurationFormatter.spoken($0) } ?? noData
            ),
            Metric(
                title: String(localized: "Longest"),
                value: statistics.longestDuration.map { ArcDurationFormatter.short($0) } ?? placeholder,
                accessibilityValue: statistics.longestDuration.map { ArcDurationFormatter.spoken($0) } ?? noData
            ),
            Metric(title: String(localized: "Current streak"), value: String(localized: "\(statistics.currentStreak) days"), accessibilityValue: nil),
            Metric(title: String(localized: "Best streak"), value: String(localized: "\(statistics.bestStreak) days"), accessibilityValue: nil),
            Metric(
                title: String(localized: "Completed"),
                value: statistics.completionRate.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? placeholder,
                accessibilityValue: statistics.completionRate == nil ? noData : nil
            )
        ]
    }

    private static func chart(from days: [ArcDailyDuration], goal: TimeInterval, range: Range) -> ArcBarChartModel {
        let hour: TimeInterval = 3600
        let bars = days.enumerated().map { index, day in
            ArcBarChartModel.Bar(value: day.duration / hour, label: axisLabel(for: day.day, index: index, count: days.count, range: range))
        }
        return ArcBarChartModel(
            bars: bars,
            goal: goal / hour,
            goalLabel: ArcDurationFormatter.short(goal)
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

    private static func chartSummary(for days: [ArcDailyDuration], goal: TimeInterval) -> String {
        let fastingDays = days.filter { $0.duration > 0 }
        guard !fastingDays.isEmpty else { return String(localized: "No finished fasts in this period") }
        let average = fastingDays.map(\.duration).reduce(0, +) / Double(fastingDays.count)
        let reached = days.filter { $0.duration >= goal }.count
        return String(localized: "Average \(ArcDurationFormatter.spoken(average)). Goal reached on \(reached) of \(days.count) days.")
    }

    private static func weight(from trend: ArcWeightTrend, unit: ArcWeightUnit) -> Weight {
        Weight(
            latest: trend.latest.map { ArcWeightFormatter.weight(kilograms: $0.kilograms, unit: unit) }
                ?? String(localized: "No entries yet"),
            change: trend.change.map { String(localized: "\(ArcWeightFormatter.change(kilograms: $0, unit: unit)) in this period") },
            chartValues: trend.entries.map { unit.value(fromKilograms: $0.kilograms) },
            recentEntries: trend.entries.suffix(3).reversed().map {
                Weight.Entry(
                    date: $0.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()),
                    value: ArcWeightFormatter.weight(kilograms: $0.kilograms, unit: unit)
                )
            }
        )
    }
}
