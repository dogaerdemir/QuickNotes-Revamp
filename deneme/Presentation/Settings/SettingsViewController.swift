import UIKit

final class SettingsViewController: UIViewController {
    private let viewModel: SettingsViewModel
    private var state = SettingsViewState(
        themeModes: AppThemeMode.allCases,
        selectedThemeMode: .system,
        showNoteContentPreview: false,
        showRelativeDates: false
    )

    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: state.themeModes.map(\.title))
        control.selectedSegmentTintColor = AppColors.accent
        control.setTitleTextAttributes([.foregroundColor: AppColors.textPrimary], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(self, action: #selector(themeModeChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = AppColors.textSecondary
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.text = "Uygulama temasını Dark, Light veya Sistem moduna alabilirsiniz."
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let previewTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Notun içeriğini göster"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let previewSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Liste hücrelerinde başlığın altında tek satır içerik önizlemesini gösterir."
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = AppColors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var previewSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColors.accent
        toggle.addTarget(self, action: #selector(previewSwitchChanged), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()

    private let relativeDateTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Göreli tarih göster"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let relativeDateSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Tarihler bugün, dün ve evvelsi gün için göreli metinle gösterilir."
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = AppColors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var relativeDateSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColors.accent
        toggle.addTarget(self, action: #selector(relativeDateSwitchChanged), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
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
        viewModel.viewWillAppear()
    }

    private func configureUI() {
        title = "Ayarlar"
        navigationItem.largeTitleDisplayMode = .always
        view.backgroundColor = AppColors.background

        let themeCardView = UIView()
        themeCardView.backgroundColor = AppColors.surface
        themeCardView.layer.cornerRadius = 16
        themeCardView.translatesAutoresizingMaskIntoConstraints = false

        let previewCardView = UIView()
        previewCardView.backgroundColor = AppColors.surface
        previewCardView.layer.cornerRadius = 16
        previewCardView.translatesAutoresizingMaskIntoConstraints = false

        let relativeDateCardView = UIView()
        relativeDateCardView.backgroundColor = AppColors.surface
        relativeDateCardView.layer.cornerRadius = 16
        relativeDateCardView.translatesAutoresizingMaskIntoConstraints = false

        themeCardView.addSubview(segmentedControl)
        themeCardView.addSubview(infoLabel)
        previewCardView.addSubview(previewTitleLabel)
        previewCardView.addSubview(previewSubtitleLabel)
        previewCardView.addSubview(previewSwitch)
        relativeDateCardView.addSubview(relativeDateTitleLabel)
        relativeDateCardView.addSubview(relativeDateSubtitleLabel)
        relativeDateCardView.addSubview(relativeDateSwitch)
        view.addSubview(themeCardView)
        view.addSubview(previewCardView)
        view.addSubview(relativeDateCardView)

        NSLayoutConstraint.activate([
            themeCardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            themeCardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            themeCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),

            segmentedControl.leadingAnchor.constraint(equalTo: themeCardView.leadingAnchor, constant: 12),
            segmentedControl.trailingAnchor.constraint(equalTo: themeCardView.trailingAnchor, constant: -12),
            segmentedControl.topAnchor.constraint(equalTo: themeCardView.topAnchor, constant: 16),

            infoLabel.leadingAnchor.constraint(equalTo: themeCardView.leadingAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: themeCardView.trailingAnchor, constant: -12),
            infoLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 14),
            infoLabel.bottomAnchor.constraint(equalTo: themeCardView.bottomAnchor, constant: -16),

            previewCardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            previewCardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            previewCardView.topAnchor.constraint(equalTo: themeCardView.bottomAnchor, constant: 14),

            previewTitleLabel.leadingAnchor.constraint(equalTo: previewCardView.leadingAnchor, constant: 12),
            previewTitleLabel.topAnchor.constraint(equalTo: previewCardView.topAnchor, constant: 14),
            previewTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: previewSwitch.leadingAnchor, constant: -10),

            previewSwitch.trailingAnchor.constraint(equalTo: previewCardView.trailingAnchor, constant: -12),
            previewSwitch.centerYAnchor.constraint(equalTo: previewTitleLabel.centerYAnchor),

            previewSubtitleLabel.leadingAnchor.constraint(equalTo: previewCardView.leadingAnchor, constant: 12),
            previewSubtitleLabel.trailingAnchor.constraint(equalTo: previewCardView.trailingAnchor, constant: -12),
            previewSubtitleLabel.topAnchor.constraint(equalTo: previewTitleLabel.bottomAnchor, constant: 8),
            previewSubtitleLabel.bottomAnchor.constraint(equalTo: previewCardView.bottomAnchor, constant: -14),

            relativeDateCardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            relativeDateCardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            relativeDateCardView.topAnchor.constraint(equalTo: previewCardView.bottomAnchor, constant: 14),

            relativeDateTitleLabel.leadingAnchor.constraint(equalTo: relativeDateCardView.leadingAnchor, constant: 12),
            relativeDateTitleLabel.topAnchor.constraint(equalTo: relativeDateCardView.topAnchor, constant: 14),
            relativeDateTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: relativeDateSwitch.leadingAnchor, constant: -10),

            relativeDateSwitch.trailingAnchor.constraint(equalTo: relativeDateCardView.trailingAnchor, constant: -12),
            relativeDateSwitch.centerYAnchor.constraint(equalTo: relativeDateTitleLabel.centerYAnchor),

            relativeDateSubtitleLabel.leadingAnchor.constraint(equalTo: relativeDateCardView.leadingAnchor, constant: 12),
            relativeDateSubtitleLabel.trailingAnchor.constraint(equalTo: relativeDateCardView.trailingAnchor, constant: -12),
            relativeDateSubtitleLabel.topAnchor.constraint(equalTo: relativeDateTitleLabel.bottomAnchor, constant: 8),
            relativeDateSubtitleLabel.bottomAnchor.constraint(equalTo: relativeDateCardView.bottomAnchor, constant: -14)
        ])
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state: state)
        }
    }

    private func render(state: SettingsViewState) {
        self.state = state
        if let index = state.themeModes.firstIndex(of: state.selectedThemeMode) {
            segmentedControl.selectedSegmentIndex = index
        }
        previewSwitch.setOn(state.showNoteContentPreview, animated: false)
        relativeDateSwitch.setOn(state.showRelativeDates, animated: false)
    }

    @objc private func themeModeChanged() {
        viewModel.selectTheme(at: segmentedControl.selectedSegmentIndex)
    }

    @objc private func previewSwitchChanged() {
        viewModel.setShowNoteContentPreview(previewSwitch.isOn)
    }

    @objc private func relativeDateSwitchChanged() {
        viewModel.setShowRelativeDates(relativeDateSwitch.isOn)
    }
}
