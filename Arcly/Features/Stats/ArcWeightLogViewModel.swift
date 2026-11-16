import Combine
import Foundation

final class ArcWeightLogViewModel {
    struct State: Equatable {
        var unitSymbol: String
        var placeholder: String
        var errorMessage: String?
        var canSave: Bool
    }

    // Wide enough for any adult, narrow enough to catch a slipped digit like "7255".
    static let plausibleKilograms: ClosedRange<Double> = 20...400

    @Published private(set) var state: State

    var onFinish: (() -> Void)?

    private let store: ArcFastStore
    private let unit: ArcWeightUnit
    private let now: () -> Date
    private var kilograms: Double?

    init(store: ArcFastStore, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.now = now
        let unit = store.preferences.weightUnit
        self.unit = unit

        let latest = store.weightEntries.max { $0.date < $1.date }
        let placeholderValue = latest.map { unit.value(fromKilograms: $0.kilograms) } ?? 0
        state = State(
            unitSymbol: ArcWeightFormatter.symbol(for: unit),
            placeholder: placeholderValue.formatted(.number.precision(.fractionLength(1))),
            errorMessage: nil,
            canSave: false
        )
    }

    func setText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let value = Self.parse(trimmed)
        let candidate = value.map { unit.kilograms(from: $0) }
        let isValid = candidate.map { Self.plausibleKilograms.contains($0) } ?? false

        kilograms = isValid ? candidate : nil
        state.canSave = isValid
        state.errorMessage = trimmed.isEmpty || isValid ? nil : rangeMessage()
    }

    func save() {
        guard let kilograms else { return }
        store.addWeightEntry(ArcWeightEntry(date: now(), kilograms: kilograms))
        onFinish?()
    }

    func cancel() {
        onFinish?()
    }

    private func rangeMessage() -> String {
        let lower = ArcWeightFormatter.weight(kilograms: Self.plausibleKilograms.lowerBound, unit: unit, fractionDigits: 0)
        let upper = ArcWeightFormatter.weight(kilograms: Self.plausibleKilograms.upperBound, unit: unit, fractionDigits: 0)
        return String(localized: "Enter a weight between \(lower) and \(upper).")
    }

    // The decimal pad shows the locale's separator, but a pasted "72.5" should still work.
    private static func parse(_ text: String) -> Double? {
        guard !text.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if let number = formatter.number(from: text) {
            return number.doubleValue
        }
        return Double(text.replacingOccurrences(of: ",", with: "."))
    }
}
