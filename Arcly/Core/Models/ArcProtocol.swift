import Foundation

nonisolated struct ArcProtocol: Codable, Hashable {
    static let sixteenEight = ArcProtocol(fastingHours: 16)
    static let eighteenSix = ArcProtocol(fastingHours: 18)
    static let twentyFour = ArcProtocol(fastingHours: 20)
    static let omad = ArcProtocol(fastingHours: 23)

    static let presets: [ArcProtocol] = [.sixteenEight, .eighteenSix, .twentyFour, .omad]
    static let customHoursRange = 12...23

    let fastingHours: Int

    init(fastingHours: Int) {
        self.fastingHours = min(max(fastingHours, Self.customHoursRange.lowerBound), Self.customHoursRange.upperBound)
    }

    var eatingHours: Int {
        24 - fastingHours
    }

    var fastingDuration: TimeInterval {
        TimeInterval(fastingHours) * 3600
    }

    var isPreset: Bool {
        Self.presets.contains(self)
    }

    var title: String {
        self == .omad ? String(localized: "OMAD") : "\(fastingHours):\(eatingHours)"
    }
}
