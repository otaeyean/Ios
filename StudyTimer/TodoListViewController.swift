import UIKit

class TodoListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var arrowButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!

    var selectedDate: Date = Date()
    var todoList: [String: [TodoItem]] = [:] 

    override func viewDidLoad() {
        super.viewDidLoad()
        configureArrowButton()
        loadTodoList()
        updateDateLabel(with: Date())

        tableView.delegate = self
        tableView.dataSource = self
    }

    // MARK: - 날짜 포맷 키
    func selectedDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    // MARK: - 날짜 표시
    func updateDateLabel(with date: Date) {
        selectedDate = date
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        let dateString = formatter.string(from: date)

        dateLabel.text = "📆 선택한 날짜: \(dateString)"
        dateLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        dateLabel.textColor = .systemIndigo
        tableView.reloadData()
    }

    // MARK: - ▼ 버튼 설정
    private func configureArrowButton() {
        arrowButton.setTitle("▼", for: .normal)
        arrowButton.setTitleColor(.systemIndigo, for: .normal)
        arrowButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        arrowButton.addTarget(self, action: #selector(showDatePickerPopup), for: .touchUpInside)
    }

    @objc func showDatePickerPopup() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        if let popupVC = sb.instantiateViewController(withIdentifier: "DatePickerPopupViewController") as? DatePickerPopupViewController {
            popupVC.modalPresentationStyle = .overFullScreen
            popupVC.modalTransitionStyle = .crossDissolve
            popupVC.onDateSelected = { [weak self] selectedDate in
                self?.updateDateLabel(with: selectedDate)
            }
            present(popupVC, animated: true)
        }
    }

    // MARK: - + 버튼 눌렀을 때
    @IBAction func addButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "새 할 일", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "할 일 제목을 입력하세요"
        }

        let addAction = UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            guard let self = self,
                  let title = alert.textFields?.first?.text,
                  !title.isEmpty else { return }

            let newTodo = TodoItem(title: title, isDone: false, memo: nil)
            let key = self.selectedDateKey()
            self.todoList[key, default: []].append(newTodo)
            self.tableView.reloadData()
            self.saveTodoList()
        }

        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = selectedDateKey()
        return todoList[key, default: []].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as? TodoTableViewCell else {
            return UITableViewCell()
        }

        let key = selectedDateKey()
        let todo = todoList[key]![indexPath.row]
        cell.configure(with: todo)

        cell.onCheckToggle = { [weak self] in
            guard let self = self else { return }
            self.todoList[key]?[indexPath.row].isDone.toggle()
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            self.saveTodoList()
        }

        return cell
    }

    // MARK: - 스와이프 삭제
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        let key = selectedDateKey()
        if editingStyle == .delete {
            todoList[key]?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            saveTodoList()
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "삭제"
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = selectedDateKey()
        let todo = todoList[key]![indexPath.row]

        let memoVC = CustomMemoViewController()
        memoVC.initialText = todo.memo
        memoVC.onSave = { [weak self] newMemo in
            guard let self = self else { return }
            self.todoList[key]?[indexPath.row].memo = newMemo
            self.saveTodoList()
            
            tableView.reloadRows(at: [indexPath], with: .automatic)

            tableView.deselectRow(at: indexPath, animated: true)
        }
        memoVC.modalPresentationStyle = .overFullScreen
        present(memoVC, animated: true)
    }


    // MARK: - 저장
    func saveTodoList() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(todoList) {
            UserDefaults.standard.set(encoded, forKey: "todoList_\(userId)")
        }
    }

    func loadTodoList() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        if let data = UserDefaults.standard.data(forKey: "todoList_\(userId)") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([String: [TodoItem]].self, from: data) {
                todoList = decoded
            }
        }
    }
}

