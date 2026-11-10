import Foundation

nonisolated enum ArcFastValidationError: Error, Equatable {
    case startInFuture
    case endInFuture
    case endNotAfterStart
    case exceedsMaximumDuration
    case overlapsAnotherFast
}

nonisolated struct ArcFastValidator {
    static let maximumDuration: TimeInterval = 48 * 3600

    /// `end == nil` means the fast is still running, so it occupies the timeline up to `now`.
    func validate(
        start: Date,
        end: Date?,
        editingFastID: ArcFast.ID,
        among fasts: [ArcFast],
        now: Date
    ) -> ArcFastValidationError? {
        if start > now {
            return .startInFuture
        }
        if let end, end > now {
            return .endInFuture
        }

        let effectiveEnd = end ?? now
        if effectiveEnd <= start {
            return .endNotAfterStart
        }
        if effectiveEnd.timeIntervalSince(start) > Self.maximumDuration {
            return .exceedsMaximumDuration
        }

        // Touching boundaries are fine: one fast may end exactly when the next one starts.
        let overlaps = fasts.contains { other in
            guard other.id != editingFastID else { return false }
            let otherEnd = other.endDate ?? now
            return start < otherEnd && other.startDate < effectiveEnd
        }
        return overlaps ? .overlapsAnotherFast : nil
    }
}
