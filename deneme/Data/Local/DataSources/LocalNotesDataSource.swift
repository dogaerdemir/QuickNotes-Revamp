import CoreData
import Foundation

final class CoreDataNotesDataSource: NotesDataSource {
    private let coreDataStack: CoreDataStack
    private var context: NSManagedObjectContext { coreDataStack.viewContext }

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    func fetchNotes(sortedBy: NoteSortOption) throws -> [NoteItem] {
        let request = CDNote.fetchRequest()
        request.sortDescriptors = sortDescriptors(for: sortedBy)
        let notes = try context.fetch(request)
        return notes.map { $0.toDomain() }
    }

    @discardableResult
    func saveNote(draft: NoteDraft, existingID: UUID?) throws -> NoteItem {
        let now = Date()
        let target: CDNote

        if let existingID {
            guard let note = try fetchNote(by: existingID) else {
                throw NotesDataError.noteNotFound
            }
            target = note
        } else {
            let note = CDNote(context: context)
            note.id = UUID()
            note.createdAt = now
            target = note
        }

        target.titleText = draft.title
        target.contentText = draft.content
        target.contentRichData = draft.richContentData
        target.isLocked = draft.isLocked
        target.isPinned = draft.isPinned
        target.updatedAt = now
        target.storageType = NoteStorageOption.local.rawValue

        coreDataStack.saveContext()
        return target.toDomain()
    }

    func deleteNotes(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }

        let request = CDNote.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids)
        let notes = try context.fetch(request)
        notes.forEach(context.delete)
        coreDataStack.saveContext()
    }

    func setPinned(ids: [UUID], isPinned: Bool) throws {
        guard !ids.isEmpty else { return }

        let request = CDNote.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids)
        let notes = try context.fetch(request)
        guard !notes.isEmpty else { return }

        let now = Date()
        notes.forEach {
            $0.isPinned = isPinned
            $0.updatedAt = now
        }

        coreDataStack.saveContext()
    }

    private func fetchNote(by id: UUID) throws -> CDNote? {
        let request = CDNote.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func sortDescriptors(for option: NoteSortOption) -> [NSSortDescriptor] {
        switch option {
        case .createdAt:
            return [
                NSSortDescriptor(key: #keyPath(CDNote.createdAt), ascending: false),
                NSSortDescriptor(key: #keyPath(CDNote.updatedAt), ascending: false)
            ]
        case .updatedAt:
            return [
                NSSortDescriptor(key: #keyPath(CDNote.updatedAt), ascending: false),
                NSSortDescriptor(key: #keyPath(CDNote.createdAt), ascending: false)
            ]
        case .alphabetical:
            return [
                NSSortDescriptor(
                    key: #keyPath(CDNote.titleText),
                    ascending: true,
                    selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
                ),
                NSSortDescriptor(key: #keyPath(CDNote.updatedAt), ascending: false)
            ]
        }
    }
}
