import UIKit

class TodoTableViewCell: UITableViewCell {
    
  
    @IBOutlet weak var memoIconView: UIImageView!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var colorDotView: UIView!
    

    var onCheckToggle: (() -> Void)?
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if checkButton == nil {
            print("nil 발생")
        } else {
            print("checkButton ")
            checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)
        }
    }
    
    // MARK: - 셀 레이아웃 조정
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if colorDotView.translatesAutoresizingMaskIntoConstraints {
            colorDotView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                colorDotView.widthAnchor.constraint(equalToConstant: 20),
                colorDotView.heightAnchor.constraint(equalTo: colorDotView.widthAnchor),
                colorDotView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                colorDotView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
        }
        
        colorDotView.layer.cornerRadius = 10
        colorDotView.clipsToBounds = true
    }
    

    func configure(with todo: TodoItem) {
        titleLabel.text = todo.title
        colorDotView.backgroundColor = UIColor.systemGray
        updateCheckState(isDone: todo.isDone)
      
        if let memo = todo.memo,
           !memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            memoIconView.image = UIImage(systemName: "note.text")
            memoIconView.tintColor = .systemYellow
            memoIconView.isHidden = false
        } else {
            memoIconView.isHidden = true
        }
    }

    // MARK: - 체크 상태 UI
    func updateCheckState(isDone: Bool) {
        if isDone {
            checkButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            titleLabel.attributedText = NSAttributedString(
                string: titleLabel.text ?? "",
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
        } else {
            checkButton.setImage(UIImage(systemName: "circle"), for: .normal)
            titleLabel.attributedText = NSAttributedString(string: titleLabel.text ?? "")
        }
    }
    
    // MARK: - 체크 버튼 액션
    @objc func checkTapped() {
        onCheckToggle?()
    }
}

