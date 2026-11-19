import UIKit

final class ArcHistoryCoordinator {
    let navigationController = UINavigationController()

    private let store: ArcFastStore

    init(store: ArcFastStore) {
        self.store = store
        navigationController.tabBarItem = UITabBarItem(
            title: String(localized: "History"),
            image: UIImage(systemName: "calendar"),
            selectedImage: nil
        )
        // The screen draws its own large title above the calendar.
        navigationController.isNavigationBarHidden = true
    }

    func start() {
        let viewModel = ArcHistoryViewModel(store: store)
        viewModel.onEditFast = { [weak self] id in self?.showEditor(forFastWithID: id) }
        viewModel.onAddFast = { [weak self] day in self?.showEditor(forNewFastOn: day) }
        navigationController.setViewControllers([ArcHistoryViewController(viewModel: viewModel)], animated: false)
    }

    private func showEditor(forFastWithID id: ArcFast.ID) {
        guard let fast = store.fasts.first(where: { $0.id == id }) else { return }
        present(ArcFastEditViewModel(fast: fast, store: store))
    }

    private func showEditor(forNewFastOn day: Date) {
        present(ArcFastEditViewModel(newFastOn: day, store: store))
    }

    private func present(_ viewModel: ArcFastEditViewModel) {
        let editor = UINavigationController(rootViewController: ArcFastEditViewController(viewModel: viewModel))
        viewModel.onFinish = { [weak editor] in
            editor?.dismiss(animated: true)
        }
        if let sheet = editor.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        navigationController.present(editor, animated: true)
    }
}
