import UIKit

final class NoteTableViewCell: UITableViewCell {
    static let reuseIdentifier = "NoteTableViewCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 2
        return label
    }()

    private let pinImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "pin.fill"))
        imageView.tintColor = AppColors.accent
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.isHidden = true
        return imageView
    }()

    private let lockImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "lock.fill"))
        imageView.tintColor = AppColors.textSecondary
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.isHidden = true
        return imageView
    }()

    private let previewLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = AppColors.textSecondary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let createdDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 1
        return label
    }()

    private let updatedDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 1
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: NoteListCellViewData) {
        titleLabel.text = data.title
        previewLabel.text = data.previewText
        previewLabel.isHidden = !data.showsPreview
        createdDateLabel.text = data.createdDateText
        updatedDateLabel.text = data.updatedDateText
        pinImageView.isHidden = !data.isPinned
        lockImageView.isHidden = !data.isLocked
    }

    private func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = AppColors.surface
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        selectionStyle = .none

        let selectedBackground = UIView()
        selectedBackground.backgroundColor = AppColors.selection
        selectedBackgroundView = selectedBackground

        let iconsStack = UIStackView(arrangedSubviews: [lockImageView, pinImageView])
        iconsStack.axis = .horizontal
        iconsStack.spacing = 6
        iconsStack.alignment = .center

        let titleRowStack = UIStackView(arrangedSubviews: [titleLabel, iconsStack])
        titleRowStack.axis = .horizontal
        titleRowStack.spacing = 8
        titleRowStack.alignment = .top

        let dateStack = UIStackView(arrangedSubviews: [createdDateLabel, updatedDateLabel])
        dateStack.axis = .vertical
        dateStack.spacing = 3

        let stack = UIStackView(arrangedSubviews: [titleRowStack, previewLabel, dateStack])
        stack.axis = .vertical
        stack.spacing = 7
        stack.setCustomSpacing(10, after: previewLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])

        pinImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        pinImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        lockImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        lockImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true

        layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        accessoryType = .none
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        let availableHeight = bounds.height - inset.top - inset.bottom

        if availableHeight <= 1 {
            contentView.frame = .zero
            selectedBackgroundView?.frame = .zero
            return
        }

        contentView.frame = bounds.inset(by: inset)
        selectedBackgroundView?.frame = bounds.inset(by: inset)
        selectedBackgroundView?.layer.cornerRadius = 12
        selectedBackgroundView?.layer.masksToBounds = true
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        selectionStyle = editing ? .default : .none
    }
}
