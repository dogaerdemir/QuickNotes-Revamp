protocol NotesPreferencesStoring: AnyObject {
    var selectedSortOption: NoteSortOption { get set }
    var showNoteContentPreview: Bool { get set }
    var showRelativeDates: Bool { get set }
}
