import Combine
import UIKit

final class ArcHistoryViewController: UIViewController {
    private typealias DataSource = UICollectionViewDiffableDataSource<Date, ArcFast.ID>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Date, ArcFast.ID>

    private let viewModel: ArcHistoryViewModel
    private var cancellables = Set<AnyCancellable>()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private lazy var dataSource = makeDataSource()

    // Copies of the latest state: @Published delivers new values before the property itself is updated.
    private var rows: [ArcFast.ID: ArcHistoryViewModel.Row] = [:]
    private var sectionTitles: [Date: String] = [:]

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
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refresh()
    }

    override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
        guard rows.isEmpty else {
            contentUnavailableConfiguration = nil
            return
        }
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: "clock.arrow.circlepath")
        configuration.imageProperties.tintColor = ArcColor.textSecondary
        configuration.text = String(localized: "No fasts yet")
        configuration.textProperties.color = ArcColor.textPrimary
        configuration.secondaryText = String(localized: "Finished fasts will show up here.")
        configuration.secondaryTextProperties.color = ArcColor.textSecondary
        contentUnavailableConfiguration = configuration
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$state
            .sink { [weak self] state in self?.apply(state) }
            .store(in: &cancellables)
    }

    private func apply(_ state: ArcHistoryViewModel.State) {
        let previousRows = rows
        rows = state.rows
        sectionTitles = Dictionary(uniqueKeysWithValues: state.sections.map { ($0.id, $0.title) })

        var snapshot = Snapshot()
        snapshot.appendSections(state.sections.map(\.id))
        for section in state.sections {
            snapshot.appendItems(section.rowIDs, toSection: section.id)
        }
        let changedIDs = state.rows.compactMap { id, row in
            previousRows[id].map { $0 != row ? id : nil } ?? nil
        }
        snapshot.reconfigureItems(changedIDs)

        dataSource.apply(snapshot, animatingDifferences: view.window != nil)
        setNeedsUpdateContentUnavailableConfiguration()
    }

    // MARK: - Collection view

    private func makeLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = ArcColor.background
        configuration.headerMode = .supplementary
        configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            self?.swipeActions(for: indexPath)
        }
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    private func makeDataSource() -> DataSource {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ArcFast.ID> { [weak self] cell, _, id in
            guard let row = self?.rows[id] else { return }
            cell.contentConfiguration = Self.content(for: row)
            var background = UIBackgroundConfiguration.listGroupedCell()
            background.backgroundColor = ArcColor.surface
            cell.backgroundConfiguration = background
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
            guard let self, let month = dataSource.sectionIdentifier(for: indexPath.section) else { return }
            var content = UIListContentConfiguration.groupedHeader()
            content.text = sectionTitles[month]
            content.textProperties.color = ArcColor.textSecondary
            header.contentConfiguration = content
        }

        let source = DataSource(collectionView: collectionView) { collectionView, indexPath, id in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: id)
        }
        source.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return source
    }

    private static func content(for row: ArcHistoryViewModel.Row) -> UIListContentConfiguration {
        var content = UIListContentConfiguration.subtitleCell()
        content.text = row.title
        content.textProperties.font = ArcFont.text(.body, weight: .semibold)
        content.textProperties.color = ArcColor.textPrimary
        content.secondaryText = row.subtitle
        content.secondaryTextProperties.font = ArcFont.text(.subheadline)
        content.secondaryTextProperties.color = ArcColor.textSecondary
        content.textToSecondaryTextVerticalPadding = ArcSpacing.xs

        // The status is also spelled out in the subtitle, so the icon is decoration for sighted users.
        switch row.status {
        case .completed:
            content.image = UIImage(systemName: "checkmark.circle.fill")
            content.imageProperties.tintColor = ArcColor.accent
        case .endedEarly:
            content.image = UIImage(systemName: "minus.circle")
            content.imageProperties.tintColor = ArcColor.textSecondary
        case .active:
            content.image = UIImage(systemName: "timer")
            content.imageProperties.tintColor = ArcColor.accentSecondary
        }
        return content
    }

    // MARK: - Deletion

    private func swipeActions(for indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return nil }
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
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.editFast(id: id)
    }
}
