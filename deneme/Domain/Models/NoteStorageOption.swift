enum NoteStorageOption: String, CaseIterable {
    case local
    case firebase

    var title: String {
        switch self {
        case .local:
            return "Lokal"
        case .firebase:
            return "Firebase"
        }
    }

    var isCurrentlyAvailable: Bool {
        switch self {
        case .local:
            return true
        case .firebase:
            return false
        }
    }
}
