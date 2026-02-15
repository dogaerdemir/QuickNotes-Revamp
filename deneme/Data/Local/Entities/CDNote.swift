import CoreData
import Foundation

@objc(CDNote)
final class CDNote: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var titleText: String
    @NSManaged var contentText: String
    @NSManaged var contentRichData: Data?
    @NSManaged var isLocked: Bool
    @NSManaged var isPinned: Bool
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var storageType: String
}

extension CDNote {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CDNote> {
        NSFetchRequest<CDNote>(entityName: "Note")
    }

    func toDomain() -> NoteItem {
        NoteItem(
            id: id,
            title: titleText,
            content: contentText,
            richContentData: contentRichData,
            isLocked: isLocked,
            isPinned: isPinned,
            createdAt: createdAt,
            updatedAt: updatedAt,
            storage: NoteStorageOption(rawValue: storageType) ?? .local
        )
    }
}
