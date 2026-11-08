import Combine
import Foundation
import UserNotifications

final class ArcReminderScheduler {
    // Fixed identifiers: re-adding a request with the same id replaces it, so resyncing never duplicates.
    private enum Identifier {
        static let goalReached = "com.arcly.reminder.goal-reached"
        static let beforeGoal = "com.arcly.reminder.before-goal"
        static let fastingStart = "com.arcly.reminder.fasting-start"
    }

    private static let beforeGoalLeadTime: TimeInterval = 30 * 60

    private let store: ArcFastStore
    private let center: UNUserNotificationCenter
    private var cancellable: AnyCancellable?

    init(store: ArcFastStore, center: UNUserNotificationCenter = .current()) {
        self.store = store
        self.center = center
    }

    func start() {
        cancellable = store.$fasts
            .map { $0.last(where: \.isActive) }
            .removeDuplicates()
            .combineLatest(store.$schedule.removeDuplicates())
            .sink { [weak self] activeFast, schedule in
                self?.sync(activeFast: activeFast, schedule: schedule)
            }
    }

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        let isGranted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        if isGranted {
            sync(activeFast: store.activeFast, schedule: store.schedule)
        }
    }

    // MARK: - Sync

    private func sync(activeFast: ArcFast?, schedule: ArcSchedule) {
        syncFastReminders(for: activeFast, reminders: schedule.reminders)
        syncFastingStartReminder(for: schedule)
    }

    private func syncFastReminders(for fast: ArcFast?, reminders: ArcReminders) {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.goalReached, Identifier.beforeGoal])
        guard let fast else { return }

        if reminders.goalReminder {
            let content = makeContent(
                title: String(localized: "Fasting goal reached"),
                body: String(localized: "You've completed your \(fast.protocolSnapshot.title) fast. Nice work.")
            )
            schedule(content, identifier: Identifier.goalReached, at: fast.goalDate)
        }
        if reminders.beforeEndReminder {
            let content = makeContent(
                title: String(localized: "30 minutes to go"),
                body: String(localized: "Your \(fast.protocolSnapshot.title) fast is almost done.")
            )
            schedule(content, identifier: Identifier.beforeGoal, at: fast.goalDate.addingTimeInterval(-Self.beforeGoalLeadTime))
        }
    }

    // A calendar trigger follows the wall clock, so the daily reminder stays at the same local time after travel.
    private func syncFastingStartReminder(for schedule: ArcSchedule) {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.fastingStart])
        guard schedule.reminders.startReminder else { return }

        let content = makeContent(
            title: String(localized: "Time to start fasting"),
            body: String(localized: "Your \(schedule.fastingProtocol.title) fasting window begins now.")
        )
        let time = DateComponents(hour: schedule.fastingStartTime.hour, minute: schedule.fastingStartTime.minute)
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        center.add(UNNotificationRequest(identifier: Identifier.fastingStart, content: content, trigger: trigger))
    }

    // Fast reminders are tied to an absolute instant, so an interval trigger is immune to time zone changes.
    private func schedule(_ content: UNNotificationContent, identifier: String, at date: Date) {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    private func makeContent(title: String, body: String) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }
}
