enum NoteSortOption: String, CaseIterable {
    case createdAt
    case updatedAt
    case alphabetical

    var menuTitle: String {
        switch self {
        case .createdAt:
            return "Yaratılış Tarihi"
        case .updatedAt:
            return "Son Düzenleme Tarihi"
        case .alphabetical:
            return "A-Z"
        }
    }
}
