
import UIKit

class CustomMemoViewController: UIViewController {

    var initialText: String?
    var onSave: ((String) -> Void)?

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.backgroundColor = UIColor.systemGray6
        tv.layer.cornerRadius = 10
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("저장", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        container.addSubview(textView)
        container.addSubview(saveButton)

        NSLayoutConstraint.activate([
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            container.heightAnchor.constraint(equalToConstant: 250),

            textView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 150),

            saveButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            saveButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 80),
            saveButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        textView.text = initialText
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    @objc private func saveTapped() {
        onSave?(textView.text)
        dismiss(animated: true)
    }
}



