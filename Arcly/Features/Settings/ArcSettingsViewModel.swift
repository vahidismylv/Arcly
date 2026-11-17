import Combine
import Foundation
import UserNotifications

final class ArcSettingsViewModel {
    enum NotificationAccess: Equatable {
        case allowed
        case denied
        case notRequested
    }

    struct State: Equatable {
        var weightUnit: ArcWeightUnit
        var isWeightLogEnabled: Bool
        var notificationAccess: NotificationAccess
        var notificationTitle: String
        var notificationDetail: String
    }

    let weightUnits = ArcWeightUnit.allCases

    @Published private(set) var state: State

    var onOpenSystemSettings: (() -> Void)?
    var onFinish: (() -> Void)?

    private let store: ArcFastStore
    private let reminderScheduler: ArcReminderScheduler
    private var cancellable: AnyCancellable?

    init(store: ArcFastStore, reminderScheduler: ArcReminderScheduler) {
        self.store = store
        self.reminderScheduler = reminderScheduler
        state = Self.makeState(preferences: store.preferences, access: .notRequested)

        cancellable = store.$preferences
            .dropFirst()
            .sink { [weak self] preferences in
                guard let self else { return }
                state = Self.makeState(preferences: preferences, access: state.notificationAccess)
            }
        refreshNotificationAccess()
    }

    func refreshNotificationAccess() {
        Task {
            let access = Self.access(for: await reminderScheduler.authorizationStatus())
            state = Self.makeState(preferences: store.preferences, access: access)
        }
    }

    func selectWeightUnit(_ unit: ArcWeightUnit) {
        var preferences = store.preferences
        preferences.weightUnit = unit
        store.updatePreferences(preferences)
    }

    func setWeightLogEnabled(_ isEnabled: Bool) {
        var preferences = store.preferences
        preferences.isWeightLogEnabled = isEnabled
        store.updatePreferences(preferences)
    }

    func openSystemSettings() {
        onOpenSystemSettings?()
    }

    func done() {
        onFinish?()
    }

    // MARK: - State

    private static func makeState(preferences: ArcPreferences, access: NotificationAccess) -> State {
        let title: String
        let detail: String
        switch access {
        case .allowed:
            title = String(localized: "Notifications are on")
            detail = String(localized: "Reminders follow the toggles in your schedule.")
        case .denied:
            title = String(localized: "Notifications are off")
            detail = String(localized: "Turn them on in Settings to get reminders about your fasts.")
        case .notRequested:
            title = String(localized: "Notifications not set up")
            detail = String(localized: "You'll be asked when you start your first fast.")
        }

        return State(
            weightUnit: preferences.weightUnit,
            isWeightLogEnabled: preferences.isWeightLogEnabled,
            notificationAccess: access,
            notificationTitle: title,
            notificationDetail: detail
        )
    }

    private static func access(for status: UNAuthorizationStatus) -> NotificationAccess {
        switch status {
        case .authorized, .provisional, .ephemeral: .allowed
        case .denied: .denied
        case .notDetermined: .notRequested
        @unknown default: .notRequested
        }
    }
}
