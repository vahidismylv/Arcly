import UIKit

final class ArcHistoryViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "History")
        view.backgroundColor = ArcColor.background
    }
}
