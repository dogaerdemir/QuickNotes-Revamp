import Foundation

final class FirebaseNotesDataSourceStub: NotesDataSource {
    func fetchNotes(sortedBy: NoteSortOption) throws -> [NoteItem] {
        throw NotesDataError.storageNotAvailable(.firebase)
    }

    @discardableResult
    func saveNote(draft: NoteDraft, existingID: UUID?) throws -> NoteItem {
        throw NotesDataError.storageNotAvailable(.firebase)
    }

    func deleteNotes(ids: [UUID]) throws {
        throw NotesDataError.storageNotAvailable(.firebase)
    }

    func setPinned(ids: [UUID], isPinned: Bool) throws {
        throw NotesDataError.storageNotAvailable(.firebase)
    }
}
