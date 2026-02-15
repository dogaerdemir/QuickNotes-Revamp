import Foundation

final class NotesRepositoryImpl: NotesRepository {
    private let localDataSource: NotesDataSource
    private let remoteDataSource: NotesDataSource

    init(localDataSource: NotesDataSource, remoteDataSource: NotesDataSource) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
    }

    func fetchNotes(sortedBy: NoteSortOption, storage: NoteStorageOption) throws -> [NoteItem] {
        try dataSource(for: storage).fetchNotes(sortedBy: sortedBy)
    }

    @discardableResult
    func saveNote(draft: NoteDraft, existingID: UUID?, storage: NoteStorageOption) throws -> NoteItem {
        try dataSource(for: storage).saveNote(draft: draft, existingID: existingID)
    }

    func deleteNotes(ids: [UUID], storage: NoteStorageOption) throws {
        try dataSource(for: storage).deleteNotes(ids: ids)
    }

    func setPinned(ids: [UUID], isPinned: Bool, storage: NoteStorageOption) throws {
        try dataSource(for: storage).setPinned(ids: ids, isPinned: isPinned)
    }

    private func dataSource(for storage: NoteStorageOption) -> NotesDataSource {
        switch storage {
        case .local:
            return localDataSource
        case .firebase:
            return remoteDataSource
        }
    }
}
