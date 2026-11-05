import Foundation

enum ArcDurationFormatter {
    private static let shortFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    private static let spokenFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    /// "12:30:05" — hours are not capped at 24.
    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%02d:%02d:%02d", total / 3600, total / 60 % 60, total % 60)
    }

    /// "4h 12m". Countdowns round up so the last minute never reads as "0m".
    static func short(_ interval: TimeInterval, roundingUp: Bool = false) -> String {
        let minutes = (max(0, interval) / 60).rounded(roundingUp ? .up : .down)
        return shortFormatter.string(from: minutes * 60) ?? ""
    }

    /// "12 hours, 30 minutes" for VoiceOver.
    static func spoken(_ interval: TimeInterval) -> String {
        let minutes = (max(0, interval) / 60).rounded(.down)
        return spokenFormatter.string(from: max(minutes, 1) * 60) ?? ""
    }
}
