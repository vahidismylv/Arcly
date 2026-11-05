import UIKit

final class ArcHistoryCoordinator {
    let navigationController = UINavigationController()

    private let store: ArcFastStore

    init(store: ArcFastStore) {
        self.store = store
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.tabBarItem = UITabBarItem(
            title: String(localized: "History"),
            image: UIImage(systemName: "list.bullet"),
            selectedImage: nil
        )
    }

    func start() {
        navigationController.setViewControllers([ArcHistoryViewController()], animated: false)
    }
}
