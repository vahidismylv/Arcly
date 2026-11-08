import Combine
import UIKit

final class ArcScheduleViewController: UIViewController {
    private let viewModel: ArcScheduleViewModel
    private let contentView: ArcScheduleView
    private var cancellables = Set<AnyCancellable>()

    private lazy var saveButton = UIBarButtonItem(
        systemItem: .save,
        primaryAction: UIAction { [weak self] _ in self?.viewModel.save() }
    )

    init(viewModel: ArcScheduleViewModel) {
        self.viewModel = viewModel
        contentView = ArcScheduleView(options: viewModel.options)
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
        title = String(localized: "Schedule")
        navigationItem.rightBarButtonItem = saveButton
        contentView.customHoursStepper.minimumValue = Double(viewModel.customHoursRange.lowerBound)
        contentView.customHoursStepper.maximumValue = Double(viewModel.customHoursRange.upperBound)
        bindControls()
        bindViewModel()
    }

    private func bindControls() {
        for (card, content) in zip(contentView.protocolCards, viewModel.options) {
            card.addAction(UIAction { [weak self] _ in self?.viewModel.select(content.option) }, for: .touchUpInside)
        }

        let stepper = contentView.customHoursStepper
        stepper.addAction(UIAction { [weak self] _ in
            self?.viewModel.setCustomHours(Int(stepper.value))
        }, for: .valueChanged)

        let picker = contentView.startTimePicker
        picker.addAction(UIAction { [weak self] _ in
            self?.viewModel.setStartTime(picker.date)
        }, for: .valueChanged)

        bindToggle(contentView.startReminderRow.toggle, to: \.startReminder)
        bindToggle(contentView.goalReminderRow.toggle, to: \.goalReminder)
        bindToggle(contentView.beforeEndReminderRow.toggle, to: \.beforeEndReminder)
    }

    private func bindToggle(_ toggle: UISwitch, to reminder: WritableKeyPath<ArcReminders, Bool>) {
        toggle.addAction(UIAction { [weak self] _ in
            self?.viewModel.setReminder(reminder, isOn: toggle.isOn)
        }, for: .valueChanged)
    }

    private func bindViewModel() {
        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)
    }

    private func render(_ state: ArcScheduleViewModel.State) {
        let isVisible = view.window != nil

        for (card, content) in zip(contentView.protocolCards, viewModel.options) {
            card.isSelected = content.option == state.selectedOption
        }
        contentView.setCustomHours(state.customHours, isVisible: state.selectedOption == .custom, animated: isVisible)

        // Writing back the same value while the wheel is spinning would make it jump.
        if contentView.startTimePicker.date != state.startTime {
            contentView.startTimePicker.setDate(state.startTime, animated: false)
        }
        contentView.startReminderRow.toggle.setOn(state.reminders.startReminder, animated: isVisible)
        contentView.goalReminderRow.toggle.setOn(state.reminders.goalReminder, animated: isVisible)
        contentView.beforeEndReminderRow.toggle.setOn(state.reminders.beforeEndReminder, animated: isVisible)

        contentView.previewDial.configure(with: state.preview, animated: false)
        saveButton.isEnabled = state.canSave
    }
}
