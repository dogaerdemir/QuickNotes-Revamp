import UIKit

final class AppContainer {
    static let shared = AppContainer()

    let coreDataStack: CoreDataStack
    let themeManager: ThemeManaging
    let notesUseCase: NotesUseCase
    let notesPreferencesStore: NotesPreferencesStoring
    let biometricAuthenticator: BiometricAuthenticating

    private init(
        coreDataStack: CoreDataStack = .shared,
        themeManager: ThemeManaging = ThemeManager.shared
    ) {
        self.coreDataStack = coreDataStack
        self.themeManager = themeManager
        self.biometricAuthenticator = BiometricAuthenticator()

        let localDataSource = CoreDataNotesDataSource(coreDataStack: coreDataStack)
        let remoteDataSource = FirebaseNotesDataSourceStub()
        let repository = NotesRepositoryImpl(localDataSource: localDataSource, remoteDataSource: remoteDataSource)

        self.notesUseCase = DefaultNotesUseCase(repository: repository)
        self.notesPreferencesStore = UserDefaultsNotesPreferencesStore()
    }

    func makeRootViewController() -> UIViewController {
        RootTabBarController(container: self)
    }

    func makeNotesListViewController() -> UIViewController {
        let viewModel = NotesListViewModel(
            useCase: notesUseCase,
            preferencesStore: notesPreferencesStore
        )

        return NotesListViewController(viewModel: viewModel) { [weak self] note, onSave in
            guard let self else { return UIViewController() }
            return self.makeNoteEditorViewController(note: note, onSave: onSave)
        }
    }

    func makeNoteEditorViewController(note: NoteItem?, onSave: (() -> Void)? = nil) -> UIViewController {
        let viewModel = NoteEditorViewModel(note: note, useCase: notesUseCase)
        let controller = NoteEditorViewController(
            viewModel: viewModel,
            biometricAuthenticator: biometricAuthenticator
        )
        controller.onSave = onSave
        return controller
    }

    func makeSettingsViewController() -> UIViewController {
        let viewModel = SettingsViewModel(
            themeManager: themeManager,
            preferencesStore: notesPreferencesStore
        )
        return SettingsViewController(viewModel: viewModel)
    }
}
