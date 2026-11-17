import Foundation

enum ArcDateFormatter {
    /// "12:00" in the user's 12- or 24-hour preference.
    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    /// "Today", "Yesterday", "Tomorrow", otherwise "Tue, 17 Nov".
    static func relativeDay(_ date: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return String(localized: "Today")
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return String(localized: "Yesterday")
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return String(localized: "Tomorrow")
        }
        return shortDay(date)
    }

    /// "Yesterday, 20:00".
    static func relativeDayAndTime(_ date: Date, now: Date, calendar: Calendar) -> String {
        let day = relativeDay(date, now: now, calendar: calendar)
        let time = time(date)
        return String(localized: "\(day), \(time)")
    }

    /// "Tue, 17 Nov".
    static func shortDay(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    /// "Tuesday, 17 November".
    static func longDay(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}
