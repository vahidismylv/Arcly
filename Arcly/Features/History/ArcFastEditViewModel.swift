import Combine
import Foundation

final class ArcFastEditViewModel {
    struct State: Equatable {
        var startDate: Date
        var endDate: Date?
        var maximumDate: Date
        var summary: String
        var errorMessage: String?
        var hasChanges: Bool
        var canSave: Bool
    }

    @Published private(set) var state: State

    var onFinish: (() -> Void)?

    private let store: ArcFastStore
    private let original: ArcFast
    private let validator = ArcFastValidator()
    private let now: () -> Date
    private var draft: ArcFast

    init(fast: ArcFast, store: ArcFastStore, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.now = now
        original = fast
        draft = fast
        state = Self.makeState(draft: fast, original: fast, fasts: store.fasts, validator: validator, now: now())
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
        store.updateFast(draft)
        onFinish?()
    }

    func cancel() {
        onFinish?()
    }

    // MARK: - State

    private func updateState() {
        state = Self.makeState(draft: draft, original: original, fasts: store.fasts, validator: validator, now: now())
    }

    private static func makeState(
        draft: ArcFast,
        original: ArcFast,
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
        let hasChanges = draft != original

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
