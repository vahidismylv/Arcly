import UIKit

final class ArcAppCoordinator {
    private let window: UIWindow
    private let tabBarController = UITabBarController()
    private let todayCoordinator: ArcTodayCoordinator
    private let historyCoordinator: ArcHistoryCoordinator
    private let statsCoordinator: ArcStatsCoordinator

    init(window: UIWindow, store: ArcFastStore) {
        self.window = window
        todayCoordinator = ArcTodayCoordinator(store: store)
        historyCoordinator = ArcHistoryCoordinator(store: store)
        statsCoordinator = ArcStatsCoordinator(store: store)
    }

    func start() {
        todayCoordinator.start()
        historyCoordinator.start()
        statsCoordinator.start()

        tabBarController.viewControllers = [
            todayCoordinator.navigationController,
            historyCoordinator.navigationController,
            statsCoordinator.navigationController
        ]

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
}
