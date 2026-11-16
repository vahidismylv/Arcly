import Foundation

enum ArcWeightFormatter {
    /// "72.5 kg", converted from the stored kilograms into the user's unit.
    static func weight(kilograms: Double, unit: ArcWeightUnit, fractionDigits: Int = 1) -> String {
        measurement(kilograms: kilograms, unit: unit).formatted(
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(fractionDigits))
            )
        )
    }

    /// "+0.8 kg" / "−1.2 kg" for a change in weight.
    static func change(kilograms: Double, unit: ArcWeightUnit) -> String {
        measurement(kilograms: kilograms, unit: unit).formatted(
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(1)).sign(strategy: .always())
            )
        )
    }

    static func symbol(for unit: ArcWeightUnit) -> String {
        MeasurementFormatter().string(from: unit.unitMass)
    }

    private static func measurement(kilograms: Double, unit: ArcWeightUnit) -> Measurement<UnitMass> {
        Measurement(value: kilograms, unit: UnitMass.kilograms).converted(to: unit.unitMass)
    }
}
