import Foundation

nonisolated struct ArcWeightEntry: Codable, Hashable, Identifiable {
    let id: UUID
    var date: Date
    var kilograms: Double

    init(id: UUID = UUID(), date: Date, kilograms: Double) {
        self.id = id
        self.date = date
        self.kilograms = kilograms
    }
}
