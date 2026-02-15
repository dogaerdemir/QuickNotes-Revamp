import Foundation

protocol NotesRepository {
    func fetchNotes(sortedBy: NoteSortOption, storage: NoteStorageOption) throws -> [NoteItem]
    @discardableResult
    func saveNote(draft: NoteDraft, existingID: UUID?, storage: NoteStorageOption) throws -> NoteItem
    func deleteNotes(ids: [UUID], storage: NoteStorageOption) throws
    func setPinned(ids: [UUID], isPinned: Bool, storage: NoteStorageOption) throws
}
