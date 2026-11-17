import Combine
import UIKit

final class ArcStatsViewController: UIViewController {
    private let viewModel: ArcStatsViewModel
    private let ranges = ArcStatsViewModel.Range.allCases
    private let contentView: ArcStatsView
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ArcStatsViewModel) {
        self.viewModel = viewModel
        contentView = ArcStatsView(ranges: ranges)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Progress")

        let rangeControl = contentView.rangeControl
        rangeControl.addAction(UIAction { [weak self] _ in
            guard let self, ranges.indices.contains(rangeControl.selectedSegmentIndex) else { return }
            viewModel.selectRange(ranges[rangeControl.selectedSegmentIndex])
        }, for: .valueChanged)

        contentView.logWeightButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.logWeight() },
            for: .primaryActionTriggered
        )

        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self else { return }
                contentView.configure(with: state, ranges: ranges, animated: view.window != nil)
            }
            .store(in: &cancellables)
    }

    // Day buckets depend on the current date, so they are recomputed whenever the tab comes back.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refresh()
    }
}
