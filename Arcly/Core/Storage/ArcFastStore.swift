import Combine
import Foundation

final class ArcFastStore {
    @Published private(set) var fasts: [ArcFast] {
        didSet { storage.save(fasts, to: .fasts) }
    }

    @Published private(set) var schedule: ArcSchedule {
        didSet { storage.save(schedule, to: .schedule) }
    }

    @Published private(set) var weightEntries: [ArcWeightEntry] {
        didSet { storage.save(weightEntries, to: .weight) }
    }

    @Published private(set) var preferences: ArcPreferences {
        didSet { storage.save(preferences, to: .preferences) }
    }

    private let storage: ArcJSONStorage

    init(directory: URL) {
        storage = ArcJSONStorage(directory: directory)
        fasts = storage.load([ArcFast].self, from: .fasts) ?? []
        schedule = storage.load(ArcSchedule.self, from: .schedule) ?? .default
        weightEntries = storage.load([ArcWeightEntry].self, from: .weight) ?? []
        preferences = storage.load(ArcPreferences.self, from: .preferences) ?? .default
    }

    var activeFast: ArcFast? {
        fasts.last { $0.isActive }
    }

    // MARK: - Fasts

    @discardableResult
    func startFast(at date: Date = .now) -> ArcFast? {
        guard activeFast == nil else { return nil }
        let fast = ArcFast(startDate: date, protocolSnapshot: schedule.fastingProtocol)
        fasts = Self.chronological(fasts + [fast])
        return fast
    }

    @discardableResult
    func endActiveFast(at date: Date = .now) -> ArcFast? {
        guard var fast = activeFast else { return nil }
        fast.endDate = max(date, fast.startDate)
        updateFast(fast)
        return fast
    }

    func updateFast(_ fast: ArcFast) {
        guard let index = fasts.firstIndex(where: { $0.id == fast.id }) else { return }
        var updated = fasts
        updated[index] = fast
        fasts = Self.chronological(updated)
    }

    func deleteFast(id: ArcFast.ID) {
        fasts.removeAll { $0.id == id }
    }

    // MARK: - Schedule & preferences

    func updateSchedule(_ schedule: ArcSchedule) {
        self.schedule = schedule
    }

    func updatePreferences(_ preferences: ArcPreferences) {
        self.preferences = preferences
    }

    // MARK: - Weight

    func addWeightEntry(_ entry: ArcWeightEntry) {
        weightEntries = (weightEntries + [entry]).sorted { $0.date < $1.date }
    }

    func deleteWeightEntry(id: ArcWeightEntry.ID) {
        weightEntries.removeAll { $0.id == id }
    }

    // MARK: - Maintenance

    func resetAllData() {
        fasts = []
        weightEntries = []
        schedule = .default
        preferences = .default
    }

    func flushPendingWrites() {
        storage.waitForPendingWrites()
    }

    private static func chronological(_ fasts: [ArcFast]) -> [ArcFast] {
        fasts.sorted { $0.startDate < $1.startDate }
    }
}
