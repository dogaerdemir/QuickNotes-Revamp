import UIKit

final class NoteEditorViewController: UIViewController {
    var onSave: (() -> Void)?

    private let viewModel: NoteEditorViewModel
    private let biometricAuthenticator: BiometricAuthenticating
    private var hasAppliedInitialContent = false
    private var hasCapturedInitialSnapshot = false
    private var currentState: NoteEditorViewState?
    private var isContentUnlockedForSession = false
    private var initialTitleText = ""
    private var initialStorageOption: NoteStorageOption = .local
    private var initialLockState = false
    private var initialPinnedState = false
    private var initialComparableContentData: Data?

    private let editorFontSize: CGFloat = 17
    private let styleButtonSize: CGFloat = 32

    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: UIImage(systemName: "checkmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(saveTapped)
        )
        item.accessibilityLabel = "Kaydet"
        item.isEnabled = false
        return item
    }()

    private lazy var pinBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: UIImage(systemName: "pin"),
            style: .plain,
            target: self,
            action: #selector(pinTapped)
        )
        item.accessibilityLabel = "Sabitle"
        return item
    }()

    private lazy var storageSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: NoteStorageOption.allCases.map(\.title))
        control.selectedSegmentTintColor = AppColors.accent
        control.setTitleTextAttributes([.foregroundColor: AppColors.textPrimary], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(self, action: #selector(storageChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private let storageHintLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColors.textSecondary
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 20, weight: .semibold)
        textField.textColor = AppColors.textPrimary
        textField.placeholder = "Başlık"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.returnKeyType = .done
        return textField
    }()

    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 17, weight: .regular)
        textView.textColor = AppColors.textPrimary
        textView.backgroundColor = AppColors.surface
        textView.layer.cornerRadius = 16
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 44, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private lazy var boldButton: UIButton = {
        makeStyleButton(
            title: "B",
            font: .boldSystemFont(ofSize: 17),
            action: #selector(toggleBold)
        )
    }()

    private lazy var italicButton: UIButton = {
        makeStyleButton(
            title: "I",
            font: .italicSystemFont(ofSize: 17),
            action: #selector(toggleItalic)
        )
    }()

    private lazy var underlineButton: UIButton = {
        makeStyleButton(
            title: "U",
            font: .systemFont(ofSize: 17, weight: .regular),
            action: #selector(toggleUnderlineStyle),
            isUnderlined: true
        )
    }()

    private lazy var formatButtonsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [boldButton, italicButton, underlineButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var lockButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 6
        button.backgroundColor = .clear
        button.tintColor = AppColors.textSecondary
        button.addTarget(self, action: #selector(lockTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let lockOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.background
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let lockOverlayTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Not Kilitli"
        label.textColor = AppColors.textPrimary
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let lockOverlaySubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Bu notu görüntülemek için biyometrik doğrulama gerekli."
        label.textColor = AppColors.textSecondary
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var unlockButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Kilidi Aç", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = AppColors.accent
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var lockOverlayStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [lockOverlayTitleLabel, lockOverlaySubtitleLabel, unlockButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init(viewModel: NoteEditorViewModel, biometricAuthenticator: BiometricAuthenticating) {
        self.viewModel = viewModel
        self.biometricAuthenticator = biometricAuthenticator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state: state)
        }

        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message: message)
        }

        viewModel.onSaved = { [weak self] _ in
            guard let self else { return }
            self.onSave?()
            self.navigationController?.popViewController(animated: true)
        }
    }

    private func configureUI() {
        view.backgroundColor = AppColors.background

        textView.delegate = self
        textView.allowsEditingTextAttributes = true
        textView.typingAttributes = defaultTypingAttributes()
        titleTextField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)

        navigationItem.rightBarButtonItems = [saveBarButtonItem, pinBarButtonItem]

        let storageCard = UIView()
        storageCard.backgroundColor = AppColors.surface
        storageCard.layer.cornerRadius = 14
        storageCard.translatesAutoresizingMaskIntoConstraints = false

        let titleContainer = UIView()
        titleContainer.backgroundColor = AppColors.surface
        titleContainer.layer.cornerRadius = 14
        titleContainer.translatesAutoresizingMaskIntoConstraints = false

        storageCard.addSubview(storageSegmentedControl)
        storageCard.addSubview(storageHintLabel)
        titleContainer.addSubview(titleTextField)
        lockOverlayView.addSubview(lockOverlayStack)

        view.addSubview(storageCard)
        view.addSubview(titleContainer)
        view.addSubview(textView)
        view.addSubview(formatButtonsStack)
        view.addSubview(lockButton)
        view.addSubview(lockOverlayView)

        NSLayoutConstraint.activate([
            storageCard.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            storageCard.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            storageCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            storageSegmentedControl.leadingAnchor.constraint(equalTo: storageCard.leadingAnchor, constant: 12),
            storageSegmentedControl.trailingAnchor.constraint(equalTo: storageCard.trailingAnchor, constant: -12),
            storageSegmentedControl.topAnchor.constraint(equalTo: storageCard.topAnchor, constant: 12),

            storageHintLabel.leadingAnchor.constraint(equalTo: storageCard.leadingAnchor, constant: 12),
            storageHintLabel.trailingAnchor.constraint(equalTo: storageCard.trailingAnchor, constant: -12),
            storageHintLabel.topAnchor.constraint(equalTo: storageSegmentedControl.bottomAnchor, constant: 10),
            storageHintLabel.bottomAnchor.constraint(equalTo: storageCard.bottomAnchor, constant: -12),

            titleContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            titleContainer.topAnchor.constraint(equalTo: storageCard.bottomAnchor, constant: 12),

            titleTextField.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 12),
            titleTextField.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -12),
            titleTextField.topAnchor.constraint(equalTo: titleContainer.topAnchor, constant: 12),
            titleTextField.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: -12),

            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            textView.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 12),
            textView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -16),

            formatButtonsStack.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 12),
            formatButtonsStack.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -10),
            boldButton.widthAnchor.constraint(equalToConstant: styleButtonSize),
            boldButton.heightAnchor.constraint(equalToConstant: styleButtonSize),
            italicButton.widthAnchor.constraint(equalToConstant: styleButtonSize),
            italicButton.heightAnchor.constraint(equalToConstant: styleButtonSize),
            underlineButton.widthAnchor.constraint(equalToConstant: styleButtonSize),
            underlineButton.heightAnchor.constraint(equalToConstant: styleButtonSize),

            lockButton.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -12),
            lockButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -10),
            lockButton.widthAnchor.constraint(equalToConstant: styleButtonSize),
            lockButton.heightAnchor.constraint(equalToConstant: styleButtonSize),

            lockOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lockOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lockOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            lockOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            lockOverlayStack.leadingAnchor.constraint(equalTo: lockOverlayView.leadingAnchor, constant: 24),
            lockOverlayStack.trailingAnchor.constraint(equalTo: lockOverlayView.trailingAnchor, constant: -24),
            lockOverlayStack.centerYAnchor.constraint(equalTo: lockOverlayView.centerYAnchor),
            unlockButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 140),
            unlockButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func render(state: NoteEditorViewState) {
        currentState = state
        title = state.isEditingExistingNote ? "Not Detayı" : "Yeni Not"

        if !hasAppliedInitialContent {
            hasAppliedInitialContent = true
            titleTextField.text = state.title
            applyInitialContent(richData: state.richContentData, fallbackText: state.content)
        }

        if let selectedIndex = NoteStorageOption.allCases.firstIndex(of: state.selectedStorage) {
            storageSegmentedControl.selectedSegmentIndex = selectedIndex
        }

        captureInitialSnapshotIfNeeded(with: state)
        storageHintLabel.text = "Firebase akışı mimariye hazırlandı. Şu an yalnızca Lokal kayıt aktif."
        updateStorageControlState()
        applyLockedPresentation()
        updateStyleButtonsState()
        updateLockButtonAppearance()
        updatePinButtonAppearance()
        updateSaveButtonState()
    }

    private func applyInitialContent(richData: Data?, fallbackText: String) {
        if let richData,
           let attributedText = try? NSAttributedString(
               data: richData,
               options: [.documentType: NSAttributedString.DocumentType.rtf],
               documentAttributes: nil
           ) {
            textView.attributedText = ensureFontAttributes(in: attributedText)
        } else {
            textView.attributedText = NSAttributedString(
                string: fallbackText,
                attributes: [.font: baseEditorFont()]
            )
        }

        textView.textColor = AppColors.textPrimary
        textView.typingAttributes = defaultTypingAttributes()
    }

    private func ensureFontAttributes(in attributedText: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributedText)

        if mutable.length == 0 {
            return NSAttributedString(string: "", attributes: [.font: baseEditorFont()])
        }

        mutable.enumerateAttribute(.font, in: NSRange(location: 0, length: mutable.length), options: []) { value, range, _ in
            if value == nil {
                mutable.addAttribute(.font, value: baseEditorFont(), range: range)
            }
        }

        return mutable
    }

    @objc private func saveTapped() {
        guard saveBarButtonItem.isEnabled else { return }
        viewModel.save(title: titleTextField.text, richText: textView.attributedText)
    }

    @objc private func pinTapped() {
        guard let state = currentState else { return }

        let targetPinnedState = !state.isPinned
        viewModel.setPinned(targetPinnedState)

        if state.isEditingExistingNote {
            let didPersist = viewModel.persistForExistingNote(
                title: titleTextField.text,
                richText: textView.attributedText
            )
            if didPersist {
                refreshInitialSnapshotFromCurrentValues()
            }
            updateSaveButtonState()
            return
        }
        updateSaveButtonState()
    }

    @objc private func titleChanged() {
        updateSaveButtonState()
    }

    @objc private func storageChanged() {
        let index = storageSegmentedControl.selectedSegmentIndex
        guard NoteStorageOption.allCases.indices.contains(index) else { return }
        viewModel.selectStorage(NoteStorageOption.allCases[index])
        updateSaveButtonState()
    }

    @objc private func toggleBold() {
        guard canAccessEditorContent else { return }
        toggle(trait: .traitBold)
    }

    @objc private func toggleItalic() {
        guard canAccessEditorContent else { return }
        toggle(trait: .traitItalic)
    }

    @objc private func toggleUnderlineStyle() {
        guard canAccessEditorContent else { return }
        let selectedRange = textView.selectedRange
        let shouldEnableUnderline = !selectionHasUnderline()

        if selectedRange.length == 0 {
            var typing = textView.typingAttributes
            if shouldEnableUnderline {
                typing[.underlineStyle] = NSUnderlineStyle.single.rawValue
            } else {
                typing.removeValue(forKey: .underlineStyle)
            }
            typing[.font] = (typing[.font] as? UIFont) ?? baseEditorFont()
            typing[.foregroundColor] = AppColors.textPrimary
            textView.typingAttributes = typing
            updateStyleButtonsState()
            updateSaveButtonState()
            return
        }

        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
        if shouldEnableUnderline {
            mutable.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
        } else {
            mutable.removeAttribute(.underlineStyle, range: selectedRange)
        }

        textView.attributedText = mutable
        textView.selectedRange = selectedRange
        syncTypingAttributesWithCursor()
        updateStyleButtonsState()
        updateSaveButtonState()
    }

    @objc private func lockTapped() {
        guard let state = currentState else { return }

        let shouldLock = !state.isLocked
        let reason = shouldLock
            ? "Notu kilitlemek için kimliğinizi doğrulayın."
            : "Not kilidini kaldırmak için kimliğinizi doğrulayın."

        authenticateUser(reason: reason) { [weak self] in
            guard let self else { return }
            self.isContentUnlockedForSession = !shouldLock
            self.viewModel.setLocked(shouldLock)
            let didPersist = self.viewModel.persistForExistingNote(
                title: self.titleTextField.text,
                richText: self.textView.attributedText
            )
            if didPersist {
                self.refreshInitialSnapshotFromCurrentValues()
            }
            self.updateSaveButtonState()
        }
    }

    @objc private func unlockTapped() {
        guard let state = currentState, state.isLocked else { return }

        authenticateUser(reason: "Kilitli notu açmak için kimliğinizi doğrulayın.") { [weak self] in
            guard let self else { return }
            self.isContentUnlockedForSession = true
            self.applyLockedPresentation()
            self.updateStorageControlState()
            self.updateSaveButtonState()
        }
    }

    private func toggle(trait: UIFontDescriptor.SymbolicTraits) {
        let selectedRange = textView.selectedRange
        let shouldEnableTrait = !selectionHasTrait(trait)

        if selectedRange.length == 0 {
            var typing = textView.typingAttributes
            let currentFont = (typing[.font] as? UIFont) ?? baseEditorFont()
            typing[.font] = font(byApplying: trait, enable: shouldEnableTrait, to: currentFont)
            typing[.foregroundColor] = AppColors.textPrimary
            textView.typingAttributes = typing
            updateStyleButtonsState()
            updateSaveButtonState()
            return
        }

        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
        mutable.enumerateAttribute(.font, in: selectedRange, options: []) { value, range, _ in
            let currentFont = (value as? UIFont) ?? baseEditorFont()
            let updatedFont = font(byApplying: trait, enable: shouldEnableTrait, to: currentFont)
            mutable.addAttribute(.font, value: updatedFont, range: range)
        }

        textView.attributedText = mutable
        textView.selectedRange = selectedRange
        syncTypingAttributesWithCursor()
        updateStyleButtonsState()
        updateSaveButtonState()
    }

    private func selectionHasTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
        guard textView.attributedText.length > 0 else {
            return currentTypingFont().fontDescriptor.symbolicTraits.contains(trait)
        }

        let selectedRange = textView.selectedRange
        if selectedRange.length == 0 {
            return currentTypingFont().fontDescriptor.symbolicTraits.contains(trait)
        }

        var hasTrait = true
        textView.attributedText.enumerateAttribute(.font, in: selectedRange, options: []) { value, _, stop in
            let font = (value as? UIFont) ?? baseEditorFont()
            if !font.fontDescriptor.symbolicTraits.contains(trait) {
                hasTrait = false
                stop.pointee = true
            }
        }

        return hasTrait
    }

    private func updateStyleButtonsState() {
        setStyleButton(boldButton, selected: selectionHasTrait(.traitBold))
        setStyleButton(italicButton, selected: selectionHasTrait(.traitItalic))
        setStyleButton(underlineButton, selected: selectionHasUnderline())
    }

    private func captureInitialSnapshotIfNeeded(with state: NoteEditorViewState) {
        guard !hasCapturedInitialSnapshot else { return }
        hasCapturedInitialSnapshot = true
        initialTitleText = titleTextField.text ?? ""
        initialStorageOption = state.selectedStorage
        initialLockState = state.isLocked
        initialPinnedState = state.isPinned
        initialComparableContentData = comparableContentData(from: textView.attributedText)
    }

    private func refreshInitialSnapshotFromCurrentValues() {
        guard let state = currentState else { return }
        hasCapturedInitialSnapshot = true
        initialTitleText = titleTextField.text ?? ""
        initialStorageOption = state.selectedStorage
        initialLockState = state.isLocked
        initialPinnedState = state.isPinned
        initialComparableContentData = comparableContentData(from: textView.attributedText)
    }

    private var currentStorageOption: NoteStorageOption {
        let index = storageSegmentedControl.selectedSegmentIndex
        if NoteStorageOption.allCases.indices.contains(index) {
            return NoteStorageOption.allCases[index]
        }
        return currentState?.selectedStorage ?? .local
    }

    private func hasPendingChanges() -> Bool {
        guard hasCapturedInitialSnapshot else { return false }

        if (titleTextField.text ?? "") != initialTitleText {
            return true
        }

        if currentStorageOption != initialStorageOption {
            return true
        }

        if (currentState?.isLocked ?? initialLockState) != initialLockState {
            return true
        }

        if (currentState?.isPinned ?? initialPinnedState) != initialPinnedState {
            return true
        }

        return comparableContentData(from: textView.attributedText) != initialComparableContentData
    }

    private func comparableContentData(from attributedText: NSAttributedString) -> Data? {
        guard attributedText.length > 0 else { return nil }

        let mutable = NSMutableAttributedString(attributedString: attributedText)
        mutable.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: mutable.length))
        return try? mutable.data(
            from: NSRange(location: 0, length: mutable.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }

    private func updateSaveButtonState() {
        saveBarButtonItem.isEnabled = canAccessEditorContent && hasPendingChanges()
    }

    private var canAccessEditorContent: Bool {
        guard let state = currentState else { return true }
        return !state.isLocked || isContentUnlockedForSession
    }

    private func applyLockedPresentation() {
        let canAccessContent = canAccessEditorContent
        titleTextField.isEnabled = canAccessContent
        textView.isEditable = canAccessContent

        boldButton.isEnabled = canAccessContent
        italicButton.isEnabled = canAccessContent
        underlineButton.isEnabled = canAccessContent
        formatButtonsStack.alpha = canAccessContent ? 1 : 0.45

        if !canAccessContent {
            view.endEditing(true)
        }

        lockOverlayView.isHidden = canAccessContent
        saveBarButtonItem.isEnabled = canAccessContent && hasPendingChanges()
    }

    private func updateStorageControlState() {
        guard let state = currentState else { return }
        let canAccessContent = canAccessEditorContent

        for (index, option) in NoteStorageOption.allCases.enumerated() {
            storageSegmentedControl.setEnabled(option.isCurrentlyAvailable && canAccessContent, forSegmentAt: index)
        }

        storageSegmentedControl.isEnabled = state.canChangeStorage && canAccessContent
    }

    private func updateLockButtonAppearance() {
        guard let state = currentState else { return }

        let symbolName = state.isLocked ? "lock.fill" : "lock.open"
        lockButton.setImage(UIImage(systemName: symbolName), for: .normal)
        lockButton.backgroundColor = state.isLocked ? AppColors.accent : .clear
        lockButton.tintColor = state.isLocked ? .white : AppColors.textSecondary
    }

    private func updatePinButtonAppearance() {
        guard let state = currentState else { return }

        pinBarButtonItem.image = UIImage(systemName: state.isPinned ? "pin.fill" : "pin")
        pinBarButtonItem.tintColor = state.isPinned ? AppColors.accent : AppColors.textSecondary
    }

    private func authenticateUser(reason: String, onSuccess: @escaping () -> Void) {
        biometricAuthenticator.authenticate(reason: reason) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                onSuccess()
            case let .failure(error):
                if let authError = error as? BiometricAuthError, case .cancelled = authError {
                    return
                }

                let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                self.showErrorAlert(message: message.isEmpty ? "Doğrulama yapılamadı." : message)
            }
        }
    }

    private func currentTypingFont() -> UIFont {
        guard textView.selectedRange.length == 0, textView.attributedText.length > 0 else {
            return (textView.typingAttributes[.font] as? UIFont) ?? baseEditorFont()
        }

        let cursor = textView.selectedRange.location
        let index = min(max(cursor == textView.attributedText.length ? cursor - 1 : cursor, 0), textView.attributedText.length - 1)
        let attrs = textView.attributedText.attributes(at: index, effectiveRange: nil)
        return (attrs[.font] as? UIFont) ?? (textView.typingAttributes[.font] as? UIFont) ?? baseEditorFont()
    }

    private func syncTypingAttributesWithCursor() {
        var attrs = textView.typingAttributes
        attrs[.font] = currentTypingFont()
        attrs[.foregroundColor] = AppColors.textPrimary
        let underlineStyle = currentTypingUnderlineStyle()
        if underlineStyle == 0 {
            attrs.removeValue(forKey: .underlineStyle)
        } else {
            attrs[.underlineStyle] = underlineStyle
        }
        textView.typingAttributes = attrs
    }

    private func selectionHasUnderline() -> Bool {
        guard textView.attributedText.length > 0 else {
            return currentTypingUnderlineStyle() != 0
        }

        let selectedRange = textView.selectedRange
        if selectedRange.length == 0 {
            return currentTypingUnderlineStyle() != 0
        }

        var hasUnderline = true
        textView.attributedText.enumerateAttribute(.underlineStyle, in: selectedRange, options: []) { value, _, stop in
            if underlineStyleValue(from: value) == 0 {
                hasUnderline = false
                stop.pointee = true
            }
        }

        return hasUnderline
    }

    private func currentTypingUnderlineStyle() -> Int {
        guard textView.selectedRange.length == 0, textView.attributedText.length > 0 else {
            return underlineStyleValue(from: textView.typingAttributes[.underlineStyle])
        }

        let cursor = textView.selectedRange.location
        let index = min(max(cursor == textView.attributedText.length ? cursor - 1 : cursor, 0), textView.attributedText.length - 1)
        let attrs = textView.attributedText.attributes(at: index, effectiveRange: nil)
        let selectionValue = underlineStyleValue(from: attrs[.underlineStyle])
        if selectionValue != 0 {
            return selectionValue
        }

        return underlineStyleValue(from: textView.typingAttributes[.underlineStyle])
    }

    private func underlineStyleValue(from value: Any?) -> Int {
        if let intValue = value as? Int {
            return intValue
        }
        if let numberValue = value as? NSNumber {
            return numberValue.intValue
        }
        return 0
    }

    private func font(
        byApplying trait: UIFontDescriptor.SymbolicTraits,
        enable: Bool,
        to font: UIFont
    ) -> UIFont {
        var traits = font.fontDescriptor.symbolicTraits
        if enable {
            traits.insert(trait)
        } else {
            traits.remove(trait)
        }

        guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else {
            return font
        }

        return UIFont(descriptor: descriptor, size: font.pointSize)
    }

    private func baseEditorFont() -> UIFont {
        .systemFont(ofSize: editorFontSize, weight: .regular)
    }

    private func defaultTypingAttributes() -> [NSAttributedString.Key: Any] {
        [
            .font: baseEditorFont(),
            .foregroundColor: AppColors.textPrimary
        ]
    }

    private func makeStyleButton(
        title: String,
        font: UIFont,
        action: Selector,
        isUnderlined: Bool = false
    ) -> UIButton {
        let button = UIButton(type: .custom)
        button.setAttributedTitle(
            styleButtonTitle(
                title: title,
                font: font,
                color: AppColors.textSecondary,
                isUnderlined: isUnderlined
            ),
            for: .normal
        )
        button.setAttributedTitle(
            styleButtonTitle(
                title: title,
                font: font,
                color: .white,
                isUnderlined: isUnderlined
            ),
            for: .selected
        )
        button.backgroundColor = .clear
        button.layer.cornerRadius = 6
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func styleButtonTitle(
        title: String,
        font: UIFont,
        color: UIColor,
        isUnderlined: Bool
    ) -> NSAttributedString {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        if isUnderlined {
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        return NSAttributedString(string: title, attributes: attrs)
    }

    private func setStyleButton(_ button: UIButton, selected: Bool) {
        button.isSelected = selected
        button.backgroundColor = selected ? AppColors.accent : .clear
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

extension NoteEditorViewController: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        syncTypingAttributesWithCursor()
        updateStyleButtonsState()
    }

    func textViewDidChange(_ textView: UITextView) {
        updateStyleButtonsState()
        updateSaveButtonState()
    }
}
