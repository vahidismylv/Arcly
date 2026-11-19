import Combine
import UIKit

final class ArcHistoryViewController: UIViewController {
    private nonisolated enum Section: Hashable {
        case calendar
        case sessions
    }

    private nonisolated enum Item: Hashable {
        case calendar
        case session(ArcFast.ID)
        case empty
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private let viewModel: ArcHistoryViewModel
    private var cancellables = Set<AnyCancellable>()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private lazy var dataSource = makeDataSource()
    private let calendarView = ArcCalendarView()
    private let addButton = ArcButton(style: .chipAccent)
    private lazy var calendarHeader = makeCalendarHeader()

    // A copy of the latest state: @Published delivers new values before the property itself is updated.
    private var state: ArcHistoryViewModel.State?

    init(viewModel: ArcHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "History")
        collectionView.backgroundColor = ArcColor.background
        collectionView.delegate = self
        _ = dataSource
        bindCalendar()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refresh()
    }

    // MARK: - Binding

    private func bindCalendar() {
        calendarView.onSelectDay = { [weak self] day in self?.viewModel.select(day: day) }
        addButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.addFast() },
            for: .primaryActionTriggered
        )
        calendarView.previousButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.showPreviousMonth() },
            for: .primaryActionTriggered
        )
        calendarView.nextButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.showNextMonth() },
            for: .primaryActionTriggered
        )
    }

    private func bindViewModel() {
        viewModel.$state
            .sink { [weak self] state in self?.apply(state) }
            .store(in: &cancellables)
    }

    private func apply(_ newState: ArcHistoryViewModel.State) {
        let previous = state
        state = newState
        calendarView.configure(with: newState)

        var snapshot = Snapshot()
        snapshot.appendSections([.calendar, .sessions])
        snapshot.appendItems([.calendar], toSection: .calendar)
        snapshot.appendItems(
            newState.sessions.isEmpty ? [.empty] : newState.sessions.map { .session($0.id) },
            toSection: .sessions
        )

        // Rows keep their identity, so edited content and a changed month height are reconfigured in place.
        var changed: [Item] = []
        if previous?.days.count != newState.days.count {
            changed.append(.calendar)
        }
        if previous?.emptyMessage != newState.emptyMessage, newState.sessions.isEmpty {
            changed.append(.empty)
        }
        let previousSessions = Dictionary(uniqueKeysWithValues: (previous?.sessions ?? []).map { ($0.id, $0) })
        for session in newState.sessions where previousSessions[session.id].map({ $0 != session }) ?? false {
            changed.append(.session(session.id))
        }
        snapshot.reconfigureItems(changed.filter { snapshot.itemIdentifiers.contains($0) })

        dataSource.apply(snapshot, animatingDifferences: view.window != nil)
        refreshSessionsHeader()
    }

    // MARK: - Layout

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] index, environment in
            guard let self, let section = dataSource.sectionIdentifier(for: index) else { return nil }
            switch section {
            case .calendar:
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(420))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [NSCollectionLayoutItem(layoutSize: size)])
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: ArcSpacing.s, leading: 20, bottom: ArcSpacing.s, trailing: 20)
                return layoutSection
            case .sessions:
                var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
                configuration.backgroundColor = .clear
                configuration.showsSeparators = false
                configuration.headerMode = .supplementary
                configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                    self?.swipeActions(for: indexPath)
                }
                let layoutSection = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
                layoutSection.interGroupSpacing = ArcSpacing.s
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: ArcSpacing.xs, leading: 20, bottom: ArcSpacing.l, trailing: 20)
                return layoutSection
            }
        }
    }

    private func makeCalendarHeader() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = String(localized: "History")
        titleLabel.font = ArcFont.text(.largeTitle, weight: .bold)
        titleLabel.textColor = ArcColor.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header

        addButton.symbolName = "plus"
        addButton.accessibilityLabel = String(localized: "Add a missed fast")
        addButton.accessibilityHint = String(localized: "Records a fast for the selected day.")
        addButton.setContentHuggingPriority(.required, for: .horizontal)

        let titleRow = UIStackView(arrangedSubviews: [titleLabel, addButton])
        titleRow.alignment = .center
        titleRow.spacing = ArcSpacing.s

        let stack = UIStackView(arrangedSubviews: [titleRow, ArcCardView(content: calendarView, insets: .uniform(ArcSpacing.s + 4))])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.m
        return stack
    }

    // MARK: - Data source

    private func makeDataSource() -> DataSource {
        let calendarRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, _ in
            guard let self else { return }
            calendarHeader.removeFromSuperview()
            calendarHeader.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(calendarHeader)
            NSLayoutConstraint.activate([
                calendarHeader.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                calendarHeader.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                calendarHeader.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                calendarHeader.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
            ])
        }

        let sessionRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ArcHistoryViewModel.Session> { cell, _, session in
            // At accessibility sizes there's no room beside the duration, so the status moves under it.
            let isLargeText = cell.traitCollection.preferredContentSizeCategory.isAccessibilityCategory
            var content = Self.content(for: session)
            if isLargeText {
                content.secondaryText = "\(session.timeRange)\n\(session.statusText)"
            }
            cell.contentConfiguration = content
            cell.preservesSuperviewLayoutMargins = false
            cell.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: ArcSpacing.m)
            cell.accessories = isLargeText ? [] : [.customView(configuration: .init(
                customView: Self.statusView(for: session),
                placement: .trailing(),
                reservedLayoutWidth: .actual
            ))]
            cell.backgroundConfiguration = Self.cardBackground()
            cell.accessibilityLabel = session.accessibilityLabel
            cell.accessibilityHint = String(localized: "Opens the editor.")
        }

        let emptyRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { cell, _, message in
            var content = UIListContentConfiguration.cell()
            content.text = message
            content.textProperties.font = ArcFont.text(.subheadline)
            content.textProperties.color = ArcColor.textSecondary
            content.textProperties.alignment = .center
            content.directionalLayoutMargins = .uniform(ArcSpacing.l)
            cell.contentConfiguration = content
            cell.backgroundConfiguration = Self.cardBackground()
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, _ in
            self?.configureSessionsHeader(header)
        }

        let source = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            switch item {
            case .calendar:
                return collectionView.dequeueConfiguredReusableCell(using: calendarRegistration, for: indexPath, item: item)
            case .session(let id):
                let session = self?.state?.sessions.first { $0.id == id }
                return session.map {
                    collectionView.dequeueConfiguredReusableCell(using: sessionRegistration, for: indexPath, item: $0)
                } ?? collectionView.dequeueConfiguredReusableCell(using: emptyRegistration, for: indexPath, item: "")
            case .empty:
                return collectionView.dequeueConfiguredReusableCell(
                    using: emptyRegistration,
                    for: indexPath,
                    item: self?.state?.emptyMessage ?? ""
                )
            }
        }
        source.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return source
    }

    private func configureSessionsHeader(_ header: UICollectionViewListCell) {
        var content = UIListContentConfiguration.plainHeader()
        content.text = String(localized: "Sessions")
        content.textProperties.font = ArcFont.text(.title3, weight: .semibold)
        content.textProperties.color = ArcColor.textPrimary
        content.secondaryText = state?.selectedDayTitle
        content.secondaryTextProperties.font = ArcFont.text(.subheadline)
        content.secondaryTextProperties.color = ArcColor.textSecondary
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: ArcSpacing.m, leading: 0, bottom: ArcSpacing.s, trailing: 0)
        header.contentConfiguration = content
        header.backgroundConfiguration = .clear()
        header.accessibilityTraits = .header
    }

    // Headers aren't covered by item reconfiguration, so the selected day is written into the visible one.
    private func refreshSessionsHeader() {
        for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader) {
            guard let header = collectionView.supplementaryView(
                forElementKind: UICollectionView.elementKindSectionHeader,
                at: indexPath
            ) as? UICollectionViewListCell else { continue }
            configureSessionsHeader(header)
        }
    }

    private static func content(for session: ArcHistoryViewModel.Session) -> UIListContentConfiguration {
        var content = UIListContentConfiguration.subtitleCell()
        content.text = session.duration
        content.textProperties.font = ArcFont.digits(size: 20, weight: .semibold, relativeTo: .title3)
        content.textProperties.color = ArcColor.textPrimary
        content.secondaryText = session.timeRange
        content.secondaryTextProperties.font = ArcFont.text(.subheadline)
        content.secondaryTextProperties.color = ArcColor.textSecondary
        content.textToSecondaryTextVerticalPadding = ArcSpacing.xs
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: ArcSpacing.m - 2, leading: ArcSpacing.m, bottom: ArcSpacing.m - 2, trailing: ArcSpacing.xs)
        return content
    }

    // Ending early is shown neutrally: a plain minus, never a checkmark or a warning colour.
    private static func statusView(for session: ArcHistoryViewModel.Session) -> UIView {
        let (symbol, color): (String, UIColor) = switch session.status {
        case .completed: ("checkmark.circle", ArcColor.accent)
        case .endedEarly: ("minus.circle", ArcColor.textSecondary)
        case .active: ("timer", ArcColor.accent)
        }

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = color
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .subheadline, scale: .medium)
        icon.setContentHuggingPriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = session.statusText
        label.font = ArcFont.text(.footnote, weight: .medium, maximumPointSize: 22)
        label.textColor = color
        label.numberOfLines = 2
        label.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.spacing = ArcSpacing.xs + 2
        stack.alignment = .center
        stack.isAccessibilityElement = false
        label.preferredMaxLayoutWidth = 96
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stack.frame.size = stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return stack
    }

    private static func cardBackground() -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.listGroupedCell()
        background.backgroundColor = ArcColor.surface
        background.cornerRadius = ArcRadius.card - 2
        background.strokeColor = ArcColor.border
        background.strokeWidth = ArcBorder.width
        return background
    }

    // MARK: - Deletion

    private func swipeActions(for indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard case .session(let id) = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let delete = UIContextualAction(style: .destructive, title: String(localized: "Delete")) { [weak self] _, _, completion in
            self?.confirmDeletion(of: id, completion: completion)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func confirmDeletion(of id: ArcFast.ID, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: String(localized: "Delete this fast?"),
            message: String(localized: "It will be removed from your history and stats."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel) { _ in
            completion(false)
        })
        alert.addAction(UIAlertAction(title: String(localized: "Delete"), style: .destructive) { [weak self] _ in
            self?.viewModel.deleteFast(id: id)
            completion(true)
        })
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDelegate

extension ArcHistoryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if case .session = dataSource.itemIdentifier(for: indexPath) { return true }
        return false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard case .session(let id) = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.editFast(id: id)
    }
}
