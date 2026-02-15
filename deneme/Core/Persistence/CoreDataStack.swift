import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init(inMemory: Bool = false) {
        let model = Self.makeManagedObjectModel()
        container = NSPersistentContainer(name: "NotesDataModel", managedObjectModel: model)

        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        if inMemory {
            description?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Persistent store failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            assertionFailure("Core Data save error: \(error.localizedDescription)")
        }
    }

    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let note = NSEntityDescription()
        note.name = "Note"
        note.managedObjectClassName = NSStringFromClass(CDNote.self)

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        id.isOptional = false

        let titleText = NSAttributeDescription()
        titleText.name = "titleText"
        titleText.attributeType = .stringAttributeType
        titleText.isOptional = false
        titleText.defaultValue = ""

        let contentText = NSAttributeDescription()
        contentText.name = "contentText"
        contentText.attributeType = .stringAttributeType
        contentText.isOptional = false
        contentText.defaultValue = ""

        let contentRichData = NSAttributeDescription()
        contentRichData.name = "contentRichData"
        contentRichData.attributeType = .binaryDataAttributeType
        contentRichData.isOptional = true
        contentRichData.allowsExternalBinaryDataStorage = true

        let isLocked = NSAttributeDescription()
        isLocked.name = "isLocked"
        isLocked.attributeType = .booleanAttributeType
        isLocked.isOptional = false
        isLocked.defaultValue = false

        let isPinned = NSAttributeDescription()
        isPinned.name = "isPinned"
        isPinned.attributeType = .booleanAttributeType
        isPinned.isOptional = false
        isPinned.defaultValue = false

        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = false

        let updatedAt = NSAttributeDescription()
        updatedAt.name = "updatedAt"
        updatedAt.attributeType = .dateAttributeType
        updatedAt.isOptional = false

        let storageType = NSAttributeDescription()
        storageType.name = "storageType"
        storageType.attributeType = .stringAttributeType
        storageType.isOptional = false
        storageType.defaultValue = NoteStorageOption.local.rawValue

        note.properties = [id, titleText, contentText, contentRichData, isLocked, isPinned, createdAt, updatedAt, storageType]
        model.entities = [note]

        return model
    }
}
