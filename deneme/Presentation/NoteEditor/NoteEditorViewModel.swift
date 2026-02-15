import Foundation
import UIKit

struct NoteEditorViewState {
    let title: String
    let content: String
    let richContentData: Data?
    let isLocked: Bool
    let isPinned: Bool
    let selectedStorage: NoteStorageOption
    let canChangeStorage: Bool
    let isEditingExistingNote: Bool
}

final class NoteEditorViewModel {
    var onStateChange: ((NoteEditorViewState) -> Void)?
    var onError: ((String) -> Void)?
    var onSaved: ((NoteItem) -> Void)?

    private let note: NoteItem?
    private let useCase: NotesUseCase
    private var selectedStorage: NoteStorageOption
    private var isLocked: Bool
    private var isPinned: Bool

    init(note: NoteItem?, useCase: NotesUseCase) {
        self.note = note
        self.useCase = useCase
        self.selectedStorage = note?.storage ?? .local
        self.isLocked = note?.isLocked ?? false
        self.isPinned = note?.isPinned ?? false
    }

    func viewDidLoad() {
        publishState()
    }

    func selectStorage(_ option: NoteStorageOption) {
        guard note == nil else { return }
        selectedStorage = option
        publishState()
    }

    func save(title: String?, richText: NSAttributedString) {
        _ = persist(title: title, richText: richText, notifyOnSaved: true)
    }

    @discardableResult
    func persistForExistingNote(title: String?, richText: NSAttributedString) -> Bool {
        guard note != nil else { return false }
        return persist(title: title, richText: richText, notifyOnSaved: false)
    }

    private func persist(title: String?, richText: NSAttributedString, notifyOnSaved: Bool) -> Bool {
        if !selectedStorage.isCurrentlyAvailable {
            onError?(NotesDataError.storageNotAvailable(selectedStorage).localizedDescription)
            return false
        }

        do {
            let draft = NoteDraft(
                title: normalized(title),
                content: normalized(richText.string),
                richContentData: try rtfData(from: richText),
                isLocked: isLocked,
                isPinned: isPinned
            )

            let saved = try useCase.saveNote(
                draft: draft,
                existingID: note?.id,
                storage: selectedStorage
            )
            if notifyOnSaved {
                onSaved?(saved)
            }
            return true
        } catch {
            onError?(error.localizedDescription)
            return false
        }
    }

    func setLocked(_ locked: Bool) {
        guard isLocked != locked else { return }
        isLocked = locked
        publishState()
    }

    func setPinned(_ pinned: Bool) {
        guard isPinned != pinned else { return }
        isPinned = pinned
        publishState()
    }

    private func publishState() {
        onStateChange?(
            NoteEditorViewState(
                title: note?.title ?? "",
                content: note?.content ?? "",
                richContentData: note?.richContentData,
                isLocked: isLocked,
                isPinned: isPinned,
                selectedStorage: selectedStorage,
                canChangeStorage: note == nil,
                isEditingExistingNote: note != nil
            )
        )
    }

    private func normalized(_ value: String?) -> String {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func rtfData(from attributedText: NSAttributedString) throws -> Data? {
        guard attributedText.length > 0 else { return nil }

        let mutable = NSMutableAttributedString(attributedString: attributedText)
        mutable.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: mutable.length))

        return try mutable.data(
            from: NSRange(location: 0, length: mutable.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }
}
