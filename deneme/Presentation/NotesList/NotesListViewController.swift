import UIKit

final class NotesListViewController: UIViewController {
    typealias NoteEditorFactory = (_ note: NoteItem?, _ onSave: @escaping () -> Void) -> UIViewController

    private let viewModel: NotesListViewModel
    private let editorFactory: NoteEditorFactory

    private var state = NotesListViewState(
        sections: [],
        isEmpty: true,
        selectedSortOption: .updatedAt,
        showNoteContentPreview: false
    )
    private var isSelectingMultipleNotes = false
    private var pendingAnimatedSectionToggle: Int?

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = AppColors.background
        tableView.tintColor = AppColors.accent
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110
        tableView.allowsSelectionDuringEditing = true
        tableView.allowsMultipleSelectionDuringEditing = true
        return tableView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Henüz not eklenmedi"
        label.textAlignment = .center
        label.textColor = AppColors.textSecondary
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    private lazy var addButton: UIBarButtonItem = {
        UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNoteTapped)
        )
    }()

    private lazy var sortButton: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down.circle"),
            style: .plain,
            target: nil,
            action: nil
        )
        item.menu = buildSortMenu(selected: state.selectedSortOption)
        return item
    }()

    private lazy var searchButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(searchTapped)
        )
    }()

    private lazy var cancelSelectionButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "Vazgeç",
            style: .plain,
            target: self,
            action: #selector(cancelSelectionMode)
        )
    }()

    private lazy var bulkActionsButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: "İşlemler",
            style: .plain,
            target: nil,
            action: nil
        )
        button.isEnabled = false
        return button
    }()

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        controller.searchResultsUpdater = self
        controller.searchBar.delegate = self
        controller.searchBar.placeholder = "Başlık veya içerikte ara"
        controller.searchBar.autocapitalizationType = .none
        controller.searchBar.autocorrectionType = .no
        return controller
    }()

    init(viewModel: NotesListViewModel, editorFactory: @escaping NoteEditorFactory) {
        self.viewModel = viewModel
        self.editorFactory = editorFactory
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !isSelectingMultipleNotes else { return }
        viewModel.viewWillAppear()
    }

    private func configureUI() {
        title = "Notlar"
        navigationItem.largeTitleDisplayMode = .always
        view.backgroundColor = AppColors.background
        definesPresentationContext = true

        tableView.register(NoteTableViewCell.self, forCellReuseIdentifier: NoteTableViewCell.reuseIdentifier)
        tableView.register(
            NoteListSectionHeaderView.self,
            forHeaderFooterViewReuseIdentifier: NoteListSectionHeaderView.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = makeTopSpacingHeader(height: 8)

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.backgroundView = emptyStateLabel
        configureNavigationItems()

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPressGesture)
    }

    private func makeTopSpacingHeader(height: CGFloat) -> UIView {
        let spacer = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: height))
        spacer.backgroundColor = .clear
        return spacer
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state: state)
        }

        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message: message)
        }
    }

    private func render(state: NotesListViewState) {
        let previousState = self.state
        self.state = state
        sortButton.menu = buildSortMenu(selected: state.selectedSortOption)
        emptyStateLabel.isHidden = !state.isEmpty

        if let section = pendingAnimatedSectionToggle,
           animateSectionToggleIfNeeded(from: previousState, to: state, section: section) {
            pendingAnimatedSectionToggle = nil
            return
        }

        pendingAnimatedSectionToggle = nil
        tableView.reloadData()
    }

    private func configureNavigationItems() {
        navigationItem.leftBarButtonItem = searchButton
        navigationItem.rightBarButtonItems = [addButton, sortButton]
    }

    private func buildSortMenu(selected: NoteSortOption) -> UIMenu {
        let actions = NoteSortOption.allCases.map { option in
            UIAction(
                title: option.menuTitle,
                state: option == selected ? .on : .off
            ) { [weak self] _ in
                self?.viewModel.selectSortOption(option)
            }
        }

        return UIMenu(title: "Sıralama Ölçütü", children: actions)
    }

    @objc private func addNoteTapped() {
        openEditor(for: nil)
    }

    @objc private func searchTapped() {
        if navigationItem.searchController == nil {
            showSearchBar()
            return
        }

        if searchController.isActive || !(searchController.searchBar.text ?? "").isEmpty {
            hideSearchBar(clearQuery: true)
        } else {
            searchController.isActive = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.searchController.searchBar.becomeFirstResponder()
            }
        }
    }

    private func openEditor(for note: NoteItem?) {
        let editor = editorFactory(note) { [weak self] in
            self?.viewModel.reloadNotes()
        }
        navigationController?.pushViewController(editor, animated: true)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, !isSelectingMultipleNotes else { return }

        let location = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location) else { return }
        guard sectionData(at: indexPath.section)?.isCollapsed == false else { return }

        enterSelectionMode(initiallySelected: indexPath)
    }

    private func enterSelectionMode(initiallySelected indexPath: IndexPath) {
        isSelectingMultipleNotes = true
        tableView.setEditing(true, animated: true)

        navigationItem.leftBarButtonItem = cancelSelectionButton
        navigationItem.rightBarButtonItems = [bulkActionsButton]

        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        updateBulkActionsButtonState()
    }

    @objc private func cancelSelectionMode() {
        exitSelectionMode()
    }

    private func exitSelectionMode() {
        tableView.indexPathsForSelectedRows?.forEach {
            tableView.deselectRow(at: $0, animated: false)
        }

        isSelectingMultipleNotes = false
        tableView.setEditing(false, animated: true)
        bulkActionsButton.title = "İşlemler"
        bulkActionsButton.menu = nil
        bulkActionsButton.isEnabled = false
        configureNavigationItems()
    }

    private func updateBulkActionsButtonState() {
        let selectedRows = tableView.indexPathsForSelectedRows ?? []
        let selectedCount = selectedRows.count
        bulkActionsButton.isEnabled = selectedCount > 0
        bulkActionsButton.title = selectedCount > 0 ? "İşlemler (\(selectedCount))" : "İşlemler"
        bulkActionsButton.menu = buildBulkActionsMenu(selectedRows: selectedRows)
    }

    private func buildBulkActionsMenu(selectedRows: [IndexPath]) -> UIMenu? {
        guard !selectedRows.isEmpty else { return nil }

        let selectedNotes = selectedRows.compactMap { viewModel.note(at: $0) }
        guard !selectedNotes.isEmpty else { return nil }

        let allPinned = selectedNotes.allSatisfy(\.isPinned)
        let targetPinnedState = !allPinned

        let pinAction = UIAction(
            title: targetPinnedState ? "Sabitle" : "Sabitlemeyi Kaldır",
            image: UIImage(systemName: targetPinnedState ? "pin.fill" : "pin.slash")
        ) { [weak self] _ in
            self?.viewModel.setPinned(at: selectedRows, isPinned: targetPinnedState)
            self?.exitSelectionMode()
        }

        let deleteAction = UIAction(
            title: "Sil",
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.presentBulkDeleteConfirmation(selectedRows: selectedRows)
        }

        return UIMenu(title: "", children: [pinAction, deleteAction])
    }

    private func presentBulkDeleteConfirmation(selectedRows: [IndexPath]) {
        let alert = UIAlertController(
            title: "Notları Sil",
            message: "Seçili notlar kalıcı olarak silinsin mi?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Vazgeç", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sil", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.viewModel.deleteNotes(at: selectedRows)
            self.exitSelectionMode()
        })

        present(alert, animated: true)
    }

    private func deleteSingleNote(at indexPath: IndexPath) {
        viewModel.deleteNote(at: indexPath)
    }

    private func togglePinnedState(at indexPath: IndexPath) {
        guard let note = viewModel.note(at: indexPath) else { return }
        viewModel.setPinned(at: indexPath, isPinned: !note.isPinned)
    }

    private func sectionData(at index: Int) -> NoteListSectionViewData? {
        guard state.sections.indices.contains(index) else { return nil }
        return state.sections[index]
    }

    private func toggleSectionAnimated(_ section: Int) {
        guard pendingAnimatedSectionToggle == nil else { return }
        guard state.sections.indices.contains(section) else { return }
        pendingAnimatedSectionToggle = section
        viewModel.toggleSection(at: section)
    }

    private func showSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.isActive = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.searchController.searchBar.becomeFirstResponder()
        }
    }

    private func hideSearchBar(clearQuery: Bool) {
        if clearQuery {
            searchController.searchBar.text = nil
            viewModel.updateSearchQuery(nil)
        }

        searchController.isActive = false
        navigationItem.searchController = nil
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    private func animateSectionToggleIfNeeded(
        from oldState: NotesListViewState,
        to newState: NotesListViewState,
        section: Int
    ) -> Bool {
        guard oldState.sections.indices.contains(section),
              newState.sections.indices.contains(section) else {
            return false
        }

        let oldSection = oldState.sections[section]
        let newSection = newState.sections[section]
        guard oldSection.kind == newSection.kind else { return false }
        guard oldSection.isCollapsed != newSection.isCollapsed else { return false }

        if let header = tableView.headerView(forSection: section) as? NoteListSectionHeaderView {
            header.setCollapsed(newSection.isCollapsed, animated: true)
        }

        let targetAlpha: CGFloat = newSection.isCollapsed ? 0 : 1
        let visibleCellsInSection = (tableView.indexPathsForVisibleRows ?? [])
            .filter { $0.section == section }
            .compactMap { tableView.cellForRow(at: $0) as? NoteTableViewCell }

        tableView.beginUpdates()
        tableView.endUpdates()

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            visibleCellsInSection.forEach { $0.contentView.alpha = targetAlpha }
        }

        return true
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

extension NotesListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        state.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionData = sectionData(at: section) else { return 0 }
        return sectionData.cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: NoteTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? NoteTableViewCell,
              let sectionData = sectionData(at: indexPath.section) else {
            return UITableViewCell()
        }

        cell.configure(with: sectionData.cells[indexPath.row])
        cell.contentView.alpha = sectionData.isCollapsed ? 0 : 1
        return cell
    }
}

extension NotesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sectionData(at: indexPath.section)?.isCollapsed == true {
            return
        }

        if isSelectingMultipleNotes {
            updateBulkActionsButtonState()
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)
        openEditor(for: viewModel.note(at: indexPath))
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard isSelectingMultipleNotes else { return }
        updateBulkActionsButtonState()
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard !isSelectingMultipleNotes, sectionData(at: indexPath.section)?.isCollapsed == false else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { [weak self] _, _, completion in
            self?.deleteSingleNote(at: indexPath)
            completion(true)
        }

        deleteAction.backgroundColor = AppColors.destructive
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }

    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard !isSelectingMultipleNotes,
              sectionData(at: indexPath.section)?.isCollapsed == false,
              let note = viewModel.note(at: indexPath) else { return nil }

        let shouldPin = !note.isPinned
        let pinAction = UIContextualAction(
            style: .normal,
            title: shouldPin ? "Sabitle" : "Kaldır"
        ) { [weak self] _, _, completion in
            self?.togglePinnedState(at: indexPath)
            completion(true)
        }

        pinAction.backgroundColor = shouldPin ? AppColors.accent : AppColors.textSecondary
        let configuration = UISwipeActionsConfiguration(actions: [pinAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if sectionData(at: indexPath.section)?.isCollapsed == true {
            return .leastNonzeroMagnitude
        }
        return state.showNoteContentPreview ? 126 : 108
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: NoteListSectionHeaderView.reuseIdentifier
        ) as? NoteListSectionHeaderView,
              let sectionData = self.sectionData(at: section) else {
            return nil
        }

        guard sectionData.showsHeader else { return nil }

        header.configure(
            title: sectionData.title,
            count: sectionData.cells.count,
            isCollapsed: sectionData.isCollapsed
        )

        header.onTap = { [weak self] in
            guard let self, !self.isSelectingMultipleNotes else { return }
            self.toggleSectionAnimated(section)
        }

        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sectionData = sectionData(at: section), sectionData.showsHeader else {
            return .leastNonzeroMagnitude
        }
        return 44
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }
}

extension NotesListViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchQuery(searchController.searchBar.text)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideSearchBar(clearQuery: true)
    }
}

private final class NoteListSectionHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "NoteListSectionHeaderView"

    var onTap: (() -> Void)?

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.navigationBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let chevronImageView: UIImageView = {
        let view = UIImageView()
        view.tintColor = AppColors.textSecondary
        view.contentMode = .center
        view.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var tapButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, count: Int, isCollapsed: Bool) {
        titleLabel.text = "\(title) (\(count))"
        chevronImageView.image = UIImage(systemName: "chevron.right")
        setCollapsed(isCollapsed, animated: false)
    }

    func setCollapsed(_ isCollapsed: Bool, animated: Bool) {
        let targetTransform = isCollapsed ? CGAffineTransform.identity : CGAffineTransform(rotationAngle: .pi / 2)

        guard animated else {
            chevronImageView.transform = targetTransform
            return
        }

        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            self.chevronImageView.transform = targetTransform
        }
    }

    private func configureUI() {
        contentView.backgroundColor = .clear
        backgroundView = UIView(frame: .zero)
        backgroundView?.backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(chevronImageView)
        containerView.addSubview(tapButton)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 18),
            chevronImageView.heightAnchor.constraint(equalToConstant: 18),

            tapButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tapButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tapButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            tapButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    @objc private func didTap() {
        onTap?()
    }
}
