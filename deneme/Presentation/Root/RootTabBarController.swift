import UIKit

final class RootTabBarController: UITabBarController {
    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let notesController = container.makeNotesListViewController()
        let notesNavigation = UINavigationController(rootViewController: notesController)
        notesNavigation.tabBarItem = UITabBarItem(
            title: "Notlar",
            image: UIImage(systemName: "note.text"),
            selectedImage: UIImage(systemName: "note.text")
        )

        let settingsController = container.makeSettingsViewController()
        let settingsNavigation = UINavigationController(rootViewController: settingsController)
        settingsNavigation.tabBarItem = UITabBarItem(
            title: "Ayarlar",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        setViewControllers([notesNavigation, settingsNavigation], animated: false)
        view.backgroundColor = AppColors.background
    }
}
