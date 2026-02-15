import Foundation

protocol NotesUseCase {
    func fetchNotes(sortedBy: NoteSortOption, storage: NoteStorageOption) throws -> [NoteItem]
    @discardableResult
    func saveNote(draft: NoteDraft, existingID: UUID?, storage: NoteStorageOption) throws -> NoteItem
    func deleteNotes(ids: [UUID], storage: NoteStorageOption) throws
    func setPinned(ids: [UUID], isPinned: Bool, storage: NoteStorageOption) throws
}

final class DefaultNotesUseCase: NotesUseCase {
    private let repository: NotesRepository

    init(repository: NotesRepository) {
        self.repository = repository
    }

    func fetchNotes(sortedBy: NoteSortOption, storage: NoteStorageOption) throws -> [NoteItem] {
        try repository.fetchNotes(sortedBy: sortedBy, storage: storage)
    }

    @discardableResult
    func saveNote(draft: NoteDraft, existingID: UUID?, storage: NoteStorageOption) throws -> NoteItem {
        try repository.saveNote(draft: draft, existingID: existingID, storage: storage)
    }

    func deleteNotes(ids: [UUID], storage: NoteStorageOption) throws {
        try repository.deleteNotes(ids: ids, storage: storage)
    }

    func setPinned(ids: [UUID], isPinned: Bool, storage: NoteStorageOption) throws {
        try repository.setPinned(ids: ids, isPinned: isPinned, storage: storage)
    }
}
