import Foundation

nonisolated struct ArcPreferences: Codable, Hashable {
    static let `default` = ArcPreferences(weightUnit: .kilograms, isWeightLogEnabled: false)

    var weightUnit: ArcWeightUnit
    var isWeightLogEnabled: Bool
}

nonisolated enum ArcWeightUnit: String, Codable, CaseIterable {
    case kilograms
    case pounds

    private var unitMass: UnitMass {
        switch self {
        case .kilograms: .kilograms
        case .pounds: .pounds
        }
    }

    func value(fromKilograms kilograms: Double) -> Double {
        Measurement(value: kilograms, unit: UnitMass.kilograms).converted(to: unitMass).value
    }

    func kilograms(from value: Double) -> Double {
        Measurement(value: value, unit: unitMass).converted(to: .kilograms).value
    }
}
