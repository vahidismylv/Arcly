import Combine
import Foundation

final class ArcFastEditViewModel {
    enum Mode {
        case edit
        case create
    }

    struct State: Equatable {
        var startDate: Date
        var endDate: Date?
        var maximumDate: Date
        var summary: String
        var errorMessage: String?
        var hasChanges: Bool
        var canSave: Bool
    }

    let mode: Mode

    var title: String {
        switch mode {
        case .edit: String(localized: "Edit Fast")
        case .create: String(localized: "Add Fast")
        }
    }

    @Published private(set) var state: State

    var onFinish: (() -> Void)?

    private let store: ArcFastStore
    private let original: ArcFast
    private let validator = ArcFastValidator()
    private let now: () -> Date
    private var draft: ArcFast

    /// Edits an existing fast. For a running fast only the start can change.
    init(fast: ArcFast, store: ArcFastStore, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.now = now
        mode = .edit
        original = fast
        draft = fast
        state = Self.makeState(draft: fast, original: fast, mode: .edit, fasts: store.fasts, validator: validator, now: now())
    }

    /// Adds a fast the user forgot to track, pre-filled for `day` from the current schedule.
    init(newFastOn day: Date, store: ArcFastStore, calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.now = now
        mode = .create
        let fast = Self.suggestedFast(on: day, schedule: store.schedule, calendar: calendar, now: now())
        original = fast
        draft = fast
        state = Self.makeState(draft: fast, original: fast, mode: .create, fasts: store.fasts, validator: validator, now: now())
    }

    func setStartDate(_ date: Date) {
        draft.startDate = date
        updateState()
    }

    func setEndDate(_ date: Date) {
        guard draft.endDate != nil else { return }
        draft.endDate = date
        updateState()
    }

    func save() {
        updateState()
        guard state.canSave else { return }
        switch mode {
        case .edit: store.updateFast(draft)
        case .create: store.addFinishedFast(draft)
        }
        onFinish?()
    }

    func cancel() {
        onFinish?()
    }

    // MARK: - State

    private func updateState() {
        state = Self.makeState(draft: draft, original: original, mode: mode, fasts: store.fasts, validator: validator, now: now())
    }

    private static func makeState(
        draft: ArcFast,
        original: ArcFast,
        mode: Mode,
        fasts: [ArcFast],
        validator: ArcFastValidator,
        now: Date
    ) -> State {
        let error = validator.validate(
            start: draft.startDate,
            end: draft.endDate,
            editingFastID: draft.id,
            among: fasts,
            now: now
        )
        let duration = ArcDurationFormatter.short(draft.duration(at: now))
        let target = ArcDurationFormatter.short(draft.targetDuration)
        // A new entry is unsaved work from the start, so it shouldn't vanish on an accidental swipe.
        let hasChanges = mode == .create || draft != original

        return State(
            startDate: draft.startDate,
            endDate: draft.endDate,
            maximumDate: now,
            summary: String(localized: "\(duration) of \(target) goal"),
            errorMessage: error.map { message(for: $0) },
            hasChanges: hasChanges,
            canSave: hasChanges && error == nil
        )
    }

    /// Starts at the scheduled time on `day` and lasts one goal. Nothing lands in the future:
    /// on today the fast ends now instead, but still starts on the selected day.
    static func suggestedFast(on day: Date, schedule: ArcSchedule, calendar: Calendar, now: Date) -> ArcFast {
        let target = schedule.fastingProtocol.fastingDuration
        let dayStart = calendar.startOfDay(for: day)
        var start = schedule.fastingStartTime.date(on: dayStart, calendar: calendar) ?? dayStart
        var end = start.addingTimeInterval(target)

        if end > now {
            end = now
            start = max(dayStart, min(start, now.addingTimeInterval(-target)))
        }
        return ArcFast(
            startDate: wholeMinute(start, calendar: calendar),
            endDate: wholeMinute(end, calendar: calendar),
            protocolSnapshot: schedule.fastingProtocol
        )
    }

    // The pickers show minutes, so seconds are dropped to keep what's shown and what's saved identical.
    private static func wholeMinute(_ date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .minute, for: date)?.start ?? date
    }

    private static func message(for error: ArcFastValidationError) -> String {
        switch error {
        case .startInFuture: String(localized: "Start can't be in the future.")
        case .endInFuture: String(localized: "End can't be in the future.")
        case .endNotAfterStart: String(localized: "End must be after start.")
        case .exceedsMaximumDuration: String(localized: "A fast can't be longer than 48 hours.")
        case .overlapsAnotherFast: String(localized: "This overlaps another fast.")
        }
    }
}
