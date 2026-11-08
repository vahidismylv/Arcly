import Combine
import Foundation

final class ArcScheduleViewModel {
    enum Option: Hashable {
        case preset(ArcProtocol)
        case custom
    }

    struct OptionContent {
        let option: Option
        let title: String
        let subtitle: String
    }

    struct State: Equatable {
        var selectedOption: Option
        var customHours: Int
        var startTime: Date
        var reminders: ArcReminders
        var preview: ArcDialModel
        var canSave: Bool
    }

    let options: [OptionContent]
    let customHoursRange = ArcProtocol.customHoursRange

    @Published private(set) var state: State

    var onSaved: (() -> Void)?

    private let store: ArcFastStore
    private let reminderScheduler: ArcReminderScheduler
    private let calendar: Calendar
    private let now: () -> Date
    private let original: ArcSchedule
    private var draft: ArcSchedule
    // Kept separately so "Custom" stays selected even when its hours match a preset.
    private var selectedOption: Option
    private var customHours: Int

    init(
        store: ArcFastStore,
        reminderScheduler: ArcReminderScheduler,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.reminderScheduler = reminderScheduler
        self.calendar = calendar
        self.now = now
        original = store.schedule
        draft = store.schedule
        customHours = store.schedule.fastingProtocol.fastingHours
        selectedOption = store.schedule.fastingProtocol.isPreset ? .preset(store.schedule.fastingProtocol) : .custom
        options = ArcProtocol.presets.map {
            OptionContent(option: .preset($0), title: $0.title, subtitle: Self.subtitle(for: $0))
        } + [
            OptionContent(
                option: .custom,
                title: String(localized: "Custom"),
                subtitle: String(localized: "\(ArcProtocol.customHoursRange.lowerBound)–\(ArcProtocol.customHoursRange.upperBound)h fast")
            )
        ]
        state = Self.makeState(
            draft: draft,
            original: original,
            selectedOption: selectedOption,
            customHours: customHours,
            now: now(),
            calendar: calendar
        )
    }

    // MARK: - Input

    func select(_ option: Option) {
        selectedOption = option
        switch option {
        case .preset(let fastingProtocol):
            draft.fastingProtocol = fastingProtocol
        case .custom:
            draft.fastingProtocol = ArcProtocol(fastingHours: customHours)
        }
        updateState()
    }

    func setCustomHours(_ hours: Int) {
        customHours = ArcProtocol(fastingHours: hours).fastingHours
        if selectedOption == .custom {
            draft.fastingProtocol = ArcProtocol(fastingHours: customHours)
        }
        updateState()
    }

    func setStartTime(_ date: Date) {
        draft.fastingStartTime = ArcTimeOfDay(date: date, calendar: calendar)
        updateState()
    }

    func setReminder(_ reminder: WritableKeyPath<ArcReminders, Bool>, isOn: Bool) {
        draft.reminders[keyPath: reminder] = isOn
        updateState()
    }

    func save() {
        store.updateSchedule(draft)
        if draft.reminders.startReminder {
            Task { await reminderScheduler.requestAuthorizationIfNeeded() }
        }
        onSaved?()
    }

    // MARK: - State

    private func updateState() {
        state = Self.makeState(
            draft: draft,
            original: original,
            selectedOption: selectedOption,
            customHours: customHours,
            now: now(),
            calendar: calendar
        )
    }

    private static func makeState(
        draft: ArcSchedule,
        original: ArcSchedule,
        selectedOption: Option,
        customHours: Int,
        now: Date,
        calendar: Calendar
    ) -> State {
        let startDate = draft.fastingStartTime.date(on: now, calendar: calendar) ?? now
        return State(
            selectedOption: selectedOption,
            customHours: customHours,
            startTime: startDate,
            reminders: draft.reminders,
            preview: preview(for: draft, startDate: startDate, now: now, calendar: calendar),
            canSave: draft != original
        )
    }

    private static func preview(for schedule: ArcSchedule, startDate: Date, now: Date, calendar: Calendar) -> ArcDialModel {
        let duration = schedule.fastingProtocol.fastingDuration
        let start = startDate.formatted(date: .omitted, time: .shortened)
        let end = startDate.addingTimeInterval(duration).formatted(date: .omitted, time: .shortened)
        let nowTime = ArcTimeOfDay(date: now, calendar: calendar)

        return ArcDialModel(
            fastingWindowStart: Double(schedule.fastingStartTime.minutesSinceMidnight) / (24 * 60),
            fastingWindowLength: Double(schedule.fastingProtocol.fastingHours) / 24,
            currentTime: Double(nowTime.minutesSinceMidnight) / (24 * 60),
            progress: 0,
            isGoalReached: false,
            phase: String(localized: "Fasting window"),
            elapsed: ArcDurationFormatter.short(duration),
            detail: "\(start) – \(end)",
            accessibilityValue: String(localized: "Fasting from \(start) to \(end)")
        )
    }

    private static func subtitle(for fastingProtocol: ArcProtocol) -> String {
        String(localized: "\(fastingProtocol.fastingHours)h fast · \(fastingProtocol.eatingHours)h eat")
    }
}
