import Foundation

nonisolated struct ArcSchedule: Codable, Hashable {
    static let `default` = ArcSchedule(
        fastingProtocol: .sixteenEight,
        fastingStartTime: ArcTimeOfDay(hour: 20, minute: 0),
        reminders: ArcReminders(startReminder: false, goalReminder: true, beforeEndReminder: true)
    )

    var fastingProtocol: ArcProtocol
    var fastingStartTime: ArcTimeOfDay
    var reminders: ArcReminders
}

nonisolated struct ArcTimeOfDay: Codable, Hashable {
    var hour: Int
    var minute: Int

    var minutesSinceMidnight: Int {
        hour * 60 + minute
    }

    func date(on day: Date, calendar: Calendar) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }
}

extension ArcTimeOfDay {
    init(date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }
}

nonisolated struct ArcReminders: Codable, Hashable {
    var startReminder: Bool
    var goalReminder: Bool
    var beforeEndReminder: Bool
}
