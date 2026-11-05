import UIKit

final class ArcStatsCoordinator {
    let navigationController = UINavigationController()

    private let store: ArcFastStore

    init(store: ArcFastStore) {
        self.store = store
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.tabBarItem = UITabBarItem(
            title: String(localized: "Stats"),
            image: UIImage(systemName: "chart.bar.xaxis"),
            selectedImage: nil
        )
    }

    func start() {
        navigationController.setViewControllers([ArcStatsViewController()], animated: false)
    }
}
