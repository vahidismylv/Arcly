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
            image: UIImage(systemName: "timer"),
            selectedImage: nil
        )
    }

    func start() {
        let viewModel = ArcTodayViewModel(store: store, reminderScheduler: reminderScheduler)
        viewModel.onShowSchedule = { [weak self] in self?.showSchedule() }
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
}
