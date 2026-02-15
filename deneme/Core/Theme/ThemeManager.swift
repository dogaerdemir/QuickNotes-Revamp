import UIKit

enum AppThemeMode: String, CaseIterable {
    case system
    case light
    case dark

    static let storageKey = "app_theme_mode"

    var title: String {
        switch self {
        case .system:
            return "Sistem"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

protocol ThemeManaging {
    var selectedMode: AppThemeMode { get }
    func apply(mode: AppThemeMode, to window: UIWindow?)
}

final class ThemeManager: ThemeManaging {
    static let shared = ThemeManager()

    private init() {}

    var selectedMode: AppThemeMode {
        guard let rawValue = UserDefaults.standard.string(forKey: AppThemeMode.storageKey),
              let mode = AppThemeMode(rawValue: rawValue)
        else {
            return .system
        }
        return mode
    }

    func apply(mode: AppThemeMode, to window: UIWindow? = nil) {
        UserDefaults.standard.set(mode.rawValue, forKey: AppThemeMode.storageKey)

        if let window {
            window.overrideUserInterfaceStyle = mode.interfaceStyle
        }

        allWindows().forEach { targetWindow in
            targetWindow.overrideUserInterfaceStyle = mode.interfaceStyle
        }
    }

    private func allWindows() -> [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
    }
}
