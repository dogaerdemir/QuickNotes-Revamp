import Foundation

protocol NotesDataSource {
    func fetchNotes(sortedBy: NoteSortOption) throws -> [NoteItem]
    @discardableResult
    func saveNote(draft: NoteDraft, existingID: UUID?) throws -> NoteItem
    func deleteNotes(ids: [UUID]) throws
    func setPinned(ids: [UUID], isPinned: Bool) throws
}
