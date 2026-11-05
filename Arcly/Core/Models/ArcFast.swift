import Foundation

nonisolated enum ArcFastStatus: Hashable {
    case active
    case completed
    case endedEarly
}

nonisolated struct ArcFast: Codable, Hashable, Identifiable {
    let id: UUID
    var startDate: Date
    var endDate: Date?
    let targetDuration: TimeInterval
    let protocolSnapshot: ArcProtocol

    init(id: UUID = UUID(), startDate: Date, endDate: Date? = nil, protocolSnapshot: ArcProtocol) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.targetDuration = protocolSnapshot.fastingDuration
        self.protocolSnapshot = protocolSnapshot
    }

    var isActive: Bool {
        endDate == nil
    }

    var goalDate: Date {
        startDate.addingTimeInterval(targetDuration)
    }

    var status: ArcFastStatus {
        guard let endDate else { return .active }
        return endDate.timeIntervalSince(startDate) >= targetDuration ? .completed : .endedEarly
    }

    // Always derived from dates: the app can be killed mid-fast, so there is no running counter to trust.
    func duration(at now: Date) -> TimeInterval {
        max(0, (endDate ?? now).timeIntervalSince(startDate))
    }
}
