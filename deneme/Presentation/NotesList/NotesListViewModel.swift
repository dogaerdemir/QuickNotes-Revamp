import Foundation
import UIKit

struct NoteListCellViewData {
    let id: UUID
    let title: String
    let previewText: String
    let showsPreview: Bool
    let createdDateText: String
    let updatedDateText: String
    let isPinned: Bool
    let isLocked: Bool
}

enum NoteListSectionKind {
    case pinned
    case regular

    var title: String {
        switch self {
        case .pinned:
            return "Sabitlenenler"
        case .regular:
            return "Diğer Notlar"
        }
    }
}

struct NoteListSectionViewData {
    let kind: NoteListSectionKind
    let title: String
    let cells: [NoteListCellViewData]
    let isCollapsed: Bool
    let showsHeader: Bool
}

struct NotesListViewState {
    let sections: [NoteListSectionViewData]
    let isEmpty: Bool
    let selectedSortOption: NoteSortOption
    let showNoteContentPreview: Bool
}

final class NotesListViewModel {
    var onStateChange: ((NotesListViewState) -> Void)?
    var onError: ((String) -> Void)?

    private let useCase: NotesUseCase
    private let preferencesStore: NotesPreferencesStoring
    private let storage: NoteStorageOption
    private let absoluteDateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private let calendar: Calendar

    private var notes: [NoteItem] = []
    private var pinnedNotes: [NoteItem] = []
    private var regularNotes: [NoteItem] = []
    private var isPinnedSectionCollapsed = false
    private var isRegularSectionCollapsed = false

    init(
        useCase: NotesUseCase,
        preferencesStore: NotesPreferencesStoring,
        storage: NoteStorageOption = .local,
        absoluteDateFormatter: DateFormatter = NotesListViewModel.makeAbsoluteFormatter(),
        timeFormatter: DateFormatter = NotesListViewModel.makeTimeFormatter(),
        calendar: Calendar = .current
    ) {
        self.useCase = useCase
        self.preferencesStore = preferencesStore
        self.storage = storage
        self.absoluteDateFormatter = absoluteDateFormatter
        self.timeFormatter = timeFormatter
        self.calendar = calendar
    }

    func viewDidLoad() {
        reloadNotes()
    }

    func viewWillAppear() {
        reloadNotes()
    }

    func reloadNotes() {
        do {
            notes = try useCase.fetchNotes(sortedBy: selectedSortOption, storage: storage)
            splitNotes()
            publishState()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    func selectSortOption(_ option: NoteSortOption) {
        preferencesStore.selectedSortOption = option
        reloadNotes()
    }

    func toggleSection(at index: Int) {
        guard stateSection(at: index) != nil else { return }

        switch stateSection(at: index)?.kind {
        case .pinned:
            isPinnedSectionCollapsed.toggle()
        case .regular:
            isRegularSectionCollapsed.toggle()
        case nil:
            break
        }

        publishState()
    }

    func note(at indexPath: IndexPath) -> NoteItem? {
        guard let section = stateSection(at: indexPath.section) else { return nil }
        let source = notesForSection(section.kind)
        guard source.indices.contains(indexPath.row) else { return nil }
        return source[indexPath.row]
    }

    func deleteNote(at indexPath: IndexPath) {
        guard let note = note(at: indexPath) else { return }
        deleteNotes(ids: [note.id])
    }

    func deleteNotes(at indexPaths: [IndexPath]) {
        let ids = idsFrom(indexPaths: indexPaths)
        deleteNotes(ids: ids)
    }

    func setPinned(at indexPath: IndexPath, isPinned: Bool) {
        guard let note = note(at: indexPath) else { return }
        setPinned(ids: [note.id], isPinned: isPinned)
    }

    func setPinned(at indexPaths: [IndexPath], isPinned: Bool) {
        let ids = idsFrom(indexPaths: indexPaths)
        setPinned(ids: ids, isPinned: isPinned)
    }

    private var selectedSortOption: NoteSortOption {
        preferencesStore.selectedSortOption
    }

    private var showNoteContentPreview: Bool {
        preferencesStore.showNoteContentPreview
    }

    private var showRelativeDates: Bool {
        preferencesStore.showRelativeDates
    }

    private func splitNotes() {
        pinnedNotes = []
        regularNotes = []

        notes.forEach { note in
            if note.isPinned {
                pinnedNotes.append(note)
            } else {
                regularNotes.append(note)
            }
        }
    }

    private func deleteNotes(ids: [UUID]) {
        guard !ids.isEmpty else { return }

        do {
            try useCase.deleteNotes(ids: ids, storage: storage)
            reloadNotes()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    private func setPinned(ids: [UUID], isPinned: Bool) {
        guard !ids.isEmpty else { return }

        do {
            try useCase.setPinned(ids: ids, isPinned: isPinned, storage: storage)
            reloadNotes()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    private func idsFrom(indexPaths: [IndexPath]) -> [UUID] {
        var result: [UUID] = []
        var seen = Set<UUID>()

        indexPaths.compactMap { note(at: $0)?.id }.forEach { id in
            guard !seen.contains(id) else { return }
            seen.insert(id)
            result.append(id)
        }

        return result
    }

    private func stateSection(at index: Int) -> NoteListSectionViewData? {
        let sections = buildSections()
        guard sections.indices.contains(index) else { return nil }
        return sections[index]
    }

    private func notesForSection(_ kind: NoteListSectionKind) -> [NoteItem] {
        switch kind {
        case .pinned:
            return pinnedNotes
        case .regular:
            return regularNotes
        }
    }

    private func buildSections() -> [NoteListSectionViewData] {
        var sections: [NoteListSectionViewData] = []

        if !pinnedNotes.isEmpty {
            sections.append(
                NoteListSectionViewData(
                    kind: .pinned,
                    title: NoteListSectionKind.pinned.title,
                    cells: makeCells(from: pinnedNotes),
                    isCollapsed: isPinnedSectionCollapsed,
                    showsHeader: true
                )
            )
        }

        if !regularNotes.isEmpty {
            sections.append(
                NoteListSectionViewData(
                    kind: .regular,
                    title: NoteListSectionKind.regular.title,
                    cells: makeCells(from: regularNotes),
                    isCollapsed: isRegularSectionCollapsed,
                    showsHeader: !pinnedNotes.isEmpty
                )
            )
        }

        return sections
    }

    private func makeCells(from notes: [NoteItem]) -> [NoteListCellViewData] {
        notes.map { note in
            let showPreview = showNoteContentPreview
            return NoteListCellViewData(
                id: note.id,
                title: note.displayTitle,
                previewText: previewText(for: note),
                showsPreview: showPreview,
                createdDateText: "Oluşturma: \(formattedDateText(note.createdAt))",
                updatedDateText: "Son Düzenleme: \(formattedDateText(note.updatedAt))",
                isPinned: note.isPinned,
                isLocked: note.isLocked
            )
        }
    }

    private func publishState() {
        let sections = buildSections()

        onStateChange?(
            NotesListViewState(
                sections: sections,
                isEmpty: sections.isEmpty,
                selectedSortOption: selectedSortOption,
                showNoteContentPreview: showNoteContentPreview
            )
        )
    }

    private func previewText(for note: NoteItem) -> String {
        if note.isLocked {
            return "Kilitli"
        }

        let normalized = note.content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return normalized.isEmpty ? "İçerik yok" : normalized
    }

    private func formattedDateText(_ date: Date) -> String {
        guard showRelativeDates else {
            return absoluteDateFormatter.string(from: date)
        }

        guard let relativePrefix = relativePrefix(for: date) else {
            return absoluteDateFormatter.string(from: date)
        }

        return "\(relativePrefix) \(timeFormatter.string(from: date))"
    }

    private func relativePrefix(for date: Date) -> String? {
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: date)
        let difference = calendar.dateComponents([.day], from: targetDay, to: today).day ?? .max

        switch difference {
        case 0:
            return "Bugün"
        case 1:
            return "Dün"
        case 2:
            return "Evvelsi Gün"
        default:
            return nil
        }
    }

    private static func makeAbsoluteFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private static func makeTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
}
