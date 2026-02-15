import Foundation

enum NotesDataError: Error, LocalizedError {
    case storageNotAvailable(NoteStorageOption)
    case noteNotFound

    var errorDescription: String? {
        switch self {
        case .storageNotAvailable(let storage):
            return "\(storage.title) kaydı henüz aktif değil. Şimdilik sadece Lokal kullanılabilir."
        case .noteNotFound:
            return "Not bulunamadı."
        }
    }
}
