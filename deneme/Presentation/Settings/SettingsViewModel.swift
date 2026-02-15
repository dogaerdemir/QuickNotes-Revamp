struct SettingsViewState {
    let themeModes: [AppThemeMode]
    let selectedThemeMode: AppThemeMode
    let showNoteContentPreview: Bool
    let showRelativeDates: Bool
}

final class SettingsViewModel {
    var onStateChange: ((SettingsViewState) -> Void)?

    private let themeManager: ThemeManaging
    private let preferencesStore: NotesPreferencesStoring

    init(themeManager: ThemeManaging, preferencesStore: NotesPreferencesStoring) {
        self.themeManager = themeManager
        self.preferencesStore = preferencesStore
    }

    func viewDidLoad() {
        publishState()
    }

    func viewWillAppear() {
        publishState()
    }

    func selectTheme(at index: Int) {
        guard AppThemeMode.allCases.indices.contains(index) else { return }
        let mode = AppThemeMode.allCases[index]
        themeManager.apply(mode: mode, to: nil)
        publishState()
    }

    func setShowNoteContentPreview(_ value: Bool) {
        preferencesStore.showNoteContentPreview = value
        publishState()
    }

    func setShowRelativeDates(_ value: Bool) {
        preferencesStore.showRelativeDates = value
        publishState()
    }

    private func publishState() {
        onStateChange?(
            SettingsViewState(
                themeModes: AppThemeMode.allCases,
                selectedThemeMode: themeManager.selectedMode,
                showNoteContentPreview: preferencesStore.showNoteContentPreview,
                showRelativeDates: preferencesStore.showRelativeDates
            )
        )
    }
}
