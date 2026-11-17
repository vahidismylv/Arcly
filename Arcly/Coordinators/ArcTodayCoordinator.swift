import UIKit

final class ArcTodayCoordinator {
    let navigationController = UINavigationController()

    private let store: ArcFastStore
    private let reminderScheduler: ArcReminderScheduler

    init(store: ArcFastStore, reminderScheduler: ArcReminderScheduler) {
        self.store = store
        self.reminderScheduler = reminderScheduler
        navigationController.tabBarItem = UITabBarItem(
            title: String(localized: "Today"),
            image: UIImage(systemName: "sun.horizon"),
            selectedImage: nil
        )
    }

    func start() {
        let viewModel = ArcTodayViewModel(store: store, reminderScheduler: reminderScheduler)
        viewModel.onShowSchedule = { [weak self] in self?.showSchedule() }
        viewModel.onShowSettings = { [weak self] in self?.showSettings() }
        navigationController.setViewControllers([ArcTodayViewController(viewModel: viewModel)], animated: false)
    }

    private func showSchedule() {
        let viewModel = ArcScheduleViewModel(store: store, reminderScheduler: reminderScheduler)
        viewModel.onSaved = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        let viewController = ArcScheduleViewController(viewModel: viewModel)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showSettings() {
        let viewModel = ArcSettingsViewModel(store: store, reminderScheduler: reminderScheduler)
        let settings = UINavigationController(rootViewController: ArcSettingsViewController(viewModel: viewModel))
        viewModel.onFinish = { [weak settings] in
            settings?.dismiss(animated: true)
        }
        viewModel.onOpenSystemSettings = {
            guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
        settings.sheetPresentationController?.prefersGrabberVisible = true
        navigationController.present(settings, animated: true)
    }
}
