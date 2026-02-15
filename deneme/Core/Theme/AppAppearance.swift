import UIKit

enum AppAppearance {
    static func apply() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = AppColors.navigationBackground
        navigationAppearance.shadowColor = AppColors.separator
        navigationAppearance.titleTextAttributes = [.foregroundColor: AppColors.textPrimary]
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: AppColors.textPrimary]

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = navigationAppearance
        navigationBar.scrollEdgeAppearance = navigationAppearance
        navigationBar.compactAppearance = navigationAppearance
        navigationBar.tintColor = AppColors.accent

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = AppColors.navigationBackground
        tabAppearance.shadowColor = AppColors.separator

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = tabAppearance
        }
        tabBar.tintColor = AppColors.accent
        tabBar.unselectedItemTintColor = AppColors.textSecondary
    }
}
