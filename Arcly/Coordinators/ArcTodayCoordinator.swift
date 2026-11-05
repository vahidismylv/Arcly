import UIKit

final class ArcTodayCoordinator {
    let navigationController = UINavigationController()

    private let store: ArcFastStore

    init(store: ArcFastStore) {
        self.store = store
        navigationController.tabBarItem = UITabBarItem(
            title: String(localized: "Today"),
            image: UIImage(systemName: "timer"),
            selectedImage: nil
        )
    }

    func start() {
        let viewModel = ArcTodayViewModel(store: store)
        navigationController.setViewControllers([ArcTodayViewController(viewModel: viewModel)], animated: false)
    }
}
