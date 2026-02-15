import Foundation

final class UserDefaultsNotesPreferencesStore: NotesPreferencesStoring {
    private enum Keys {
        static let selectedSortOption = "notes_selected_sort_option"
        static let showNoteContentPreview = "notes_show_note_content_preview"
        static let showRelativeDates = "notes_show_relative_dates"
    }

    var selectedSortOption: NoteSortOption {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: Keys.selectedSortOption),
                  let option = NoteSortOption(rawValue: rawValue)
            else {
                return .updatedAt
            }
            return option
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.selectedSortOption)
        }
    }

    var showNoteContentPreview: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.showNoteContentPreview)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.showNoteContentPreview)
        }
    }

    var showRelativeDates: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.showRelativeDates)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.showRelativeDates)
        }
    }
}
