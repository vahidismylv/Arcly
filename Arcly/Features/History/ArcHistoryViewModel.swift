import Combine
import Foundation

final class ArcHistoryViewModel {
    struct Section: Hashable, Identifiable {
        let id: Date
        let title: String
        let rowIDs: [ArcFast.ID]
    }

    struct Row: Equatable {
        let title: String
        let subtitle: String
        let status: ArcFastStatus
    }

    struct State: Equatable {
        var sections: [Section]
        var rows: [ArcFast.ID: Row]

        var isEmpty: Bool {
            sections.isEmpty
        }
    }

    @Published private(set) var state = State(sections: [], rows: [:])

    var onEditFast: ((ArcFast.ID) -> Void)?

    private let store: ArcFastStore
    private let calendar: Calendar
    private let now: () -> Date
    private var cancellable: AnyCancellable?

    init(store: ArcFastStore, calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.calendar = calendar
        self.now = now
        cancellable = store.$fasts.sink { [weak self] fasts in
            self?.rebuild(from: fasts)
        }
    }

    // The running fast's row shows elapsed time, which only needs to be fresh when the list appears.
    func refresh() {
        rebuild(from: store.fasts)
    }

    func editFast(id: ArcFast.ID) {
        onEditFast?(id)
    }

    func deleteFast(id: ArcFast.ID) {
        store.deleteFast(id: id)
    }

    // MARK: - State

    private func rebuild(from fasts: [ArcFast]) {
        let date = now()
        let newestFirst = fasts.sorted { $0.startDate > $1.startDate }
        let byMonth = Dictionary(grouping: newestFirst) { monthStart(of: $0.startDate) }

        let sections = byMonth.keys.sorted(by: >).map { month in
            Section(
                id: month,
                title: month.formatted(.dateTime.month(.wide).year()),
                rowIDs: (byMonth[month] ?? []).map(\.id)
            )
        }
        let rows = Dictionary(uniqueKeysWithValues: newestFirst.map { ($0.id, row(for: $0, now: date)) })

        let newState = State(sections: sections, rows: rows)
        if newState != state {
            state = newState
        }
    }

    private func row(for fast: ArcFast, now: Date) -> Row {
        let duration = ArcDurationFormatter.short(fast.duration(at: now))
        let target = ArcDurationFormatter.short(fast.targetDuration)
        let statusText = switch fast.status {
        case .active: String(localized: "In progress")
        case .completed: String(localized: "Completed")
        case .endedEarly: String(localized: "Ended early")
        }

        return Row(
            title: fast.startDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()),
            subtitle: String(localized: "\(duration) of \(target) · \(statusText)"),
            status: fast.status
        )
    }

    private func monthStart(of date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }
}
