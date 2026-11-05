import UIKit

enum ArcAppearance {
    static func apply() {
        applyNavigationBar()
        applyTabBar()
    }

    private static func applyNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ArcColor.background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: ArcColor.textPrimary,
            .font: ArcFont.text(.headline, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: ArcColor.textPrimary,
            .font: ArcFont.text(.largeTitle, weight: .bold)
        ]

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }

    private static func applyTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ArcColor.surface
        appearance.shadowColor = ArcColor.separator

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.unselectedItemTintColor = ArcColor.textSecondary
    }
}
