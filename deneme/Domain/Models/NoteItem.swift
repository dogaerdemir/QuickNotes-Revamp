import Foundation

struct NoteItem: Equatable {
    let id: UUID
    var title: String
    var content: String
    var richContentData: Data?
    var isLocked: Bool
    var isPinned: Bool
    let createdAt: Date
    var updatedAt: Date
    let storage: NoteStorageOption

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Başlıksız Not" : trimmed
    }
}
