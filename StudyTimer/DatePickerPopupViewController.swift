import UIKit

class DatePickerPopupViewController: UIViewController {


    @IBOutlet weak var datePicker: UIDatePicker!

    var onDateSelected: ((Date) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.locale = Locale(identifier: "ko_KR")
    }


    @IBAction func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }


    @IBAction func applyTapped(_ sender: UIButton) {
        onDateSelected?(datePicker.date)
        dismiss(animated: true)
    }
}

