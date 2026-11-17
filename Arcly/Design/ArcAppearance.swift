import UIKit

enum ArcAppearance {
    static func apply() {
        applyNavigationBar()
        applyTabBar()
        applyControls()
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

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }

    // The tab bar keeps the system material so it behaves natively on every iOS version (glass on iOS 26).
    private static func applyTabBar() {
        UITabBar.appearance().unselectedItemTintColor = ArcColor.textSecondary
    }

    private static func applyControls() {
        UISwitch.appearance().onTintColor = ArcColor.accent

        let segmented = UISegmentedControl.appearance()
        segmented.selectedSegmentTintColor = ArcColor.accent
        segmented.backgroundColor = ArcColor.surface
        segmented.setTitleTextAttributes([
            .foregroundColor: ArcColor.onAccent,
            .font: ArcFont.text(.subheadline, weight: .semibold)
        ], for: .selected)
        segmented.setTitleTextAttributes([
            .foregroundColor: ArcColor.textSecondary,
            .font: ArcFont.text(.subheadline, weight: .medium)
        ], for: .normal)
    }
}
