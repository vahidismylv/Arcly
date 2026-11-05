import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private let store = ArcFastStore(directory: .applicationSupportDirectory)
    private var appCoordinator: ArcAppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        ArcAppearance.apply()

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        window.tintColor = ArcColor.accent

        let coordinator = ArcAppCoordinator(window: window, store: store)
        coordinator.start()

        self.window = window
        appCoordinator = coordinator
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        store.flushPendingWrites()
    }
}
