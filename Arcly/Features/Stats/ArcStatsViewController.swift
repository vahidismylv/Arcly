import UIKit

final class ArcStatsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Stats")
        view.backgroundColor = ArcColor.background
    }
}
