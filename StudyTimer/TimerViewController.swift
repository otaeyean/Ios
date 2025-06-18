import UIKit
import CoreMotion
import AVFoundation

class TimerViewController: UIViewController {

    @IBOutlet weak var outerStackView: UIStackView!
    @IBOutlet weak var totalTitleLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var normalButton: UIButton!
    @IBOutlet weak var focusButton: UIButton!
    @IBOutlet weak var soundButton: UIButton!

    enum TimerMode {
        case normal
        case focus
    }

    var selectedMode: TimerMode = .normal
    var startTimerMode: TimerMode?
    var normalTimers: [String: Int] = [:]
    var focusTimers: [String: Int] = [:]
    var currentRunningSubject: String?
    var mainTimer: Timer?
    let motionManager = CMMotionManager()

    var alertSeconds: Int? = nil
    var isAlertTriggered: Bool = false

    var audioPlayer: AVAudioPlayer?
    var selectedSoundName: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        updateModeButtons()
        updateSoundButtonIcon()
        
        // ✅ 오른쪽 상단 로그아웃 버튼 추가
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "로그아웃",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    @objc func logoutTapped() {
        // ✅ 저장된 로그인 정보 제거
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userPw")

        // ✅ 로그인 화면으로 이동
        let sb = UIStoryboard(name: "Main", bundle: nil)
        if let loginVC = sb.instantiateViewController(identifier: "LoginViewController") as? LoginViewController {
            let nav = UINavigationController(rootViewController: loginVC)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true)
        }
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        for view in outerStackView.arrangedSubviews {
            if view is UIStackView {
                outerStackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
        }

        normalTimers = [:]
        focusTimers = [:]
    

        loadTimersFromUserDefaults()
        updateTimersDisplay()
        updateTotalTime()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        if selectedMode == .focus && currentRunningSubject != nil {
            startMotionDetection()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
        if selectedMode == .focus && currentRunningSubject != nil {
            stopFocusModeWithAlert(reason: "다른 화면으로 이동했습니다.")
        }
    }

    override var canBecomeFirstResponder: Bool { true }

    @objc func appDidEnterBackground() {
        if selectedMode == .focus && currentRunningSubject != nil {
            stopFocusModeWithAlert(reason: "앱이 백그라운드로 전환되었습니다.")
        }
    }

    func startMotionDetection() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.5
        motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion = motion else { return }
            if abs(motion.attitude.pitch) > 0.7 || abs(motion.attitude.roll) > 0.7 ||
                abs(motion.userAcceleration.x) > 0.3 || abs(motion.userAcceleration.y) > 0.3 || abs(motion.userAcceleration.z) > 0.3 {
                self.stopFocusModeWithAlert(reason: "기기가 움직였습니다.")
            }
        }
    }

    func stopMotionDetection() {
        motionManager.stopDeviceMotionUpdates()
    }

    func stopFocusModeWithAlert(reason: String) {
        mainTimer?.invalidate()
        mainTimer = nil
        currentRunningSubject = nil
        stopMotionDetection()

        let alert = UIAlertController(
            title: "집중모드 중단",
            message: "\(reason)\n타이머가 자동으로 정지되었습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @IBAction func normalButtonTapped(_ sender: UIButton) {
        selectedMode = .normal
        stopMotionDetection()
        updateModeButtons()
        updateTimersDisplay()
    }

    @IBAction func focusButtonTapped(_ sender: UIButton) {
        selectedMode = .focus
        if currentRunningSubject != nil {
            startMotionDetection()
        }
        updateModeButtons()
        updateTimersDisplay()
    }

    func updateModeButtons() {
        let selectedBg = UIColor(white: 0.9, alpha: 1)
        let unselectedBg = UIColor.clear
        let selectedText = UIColor.black
        let unselectedText = UIColor.lightGray

        [normalButton, focusButton].forEach {
            $0?.layer.cornerRadius = 8
            $0?.clipsToBounds = true
            $0?.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            $0?.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = UIColor.lightGray.cgColor
        }

        normalButton.backgroundColor = selectedMode == .normal ? selectedBg : unselectedBg
        normalButton.setTitleColor(selectedMode == .normal ? selectedText : unselectedText, for: .normal)
        focusButton.backgroundColor = selectedMode == .focus ? selectedBg : unselectedBg
        focusButton.setTitleColor(selectedMode == .focus ? selectedText : unselectedText, for: .normal)
    }

    @IBAction func addSubjectTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "과목 추가", message: "과목 이름을 입력하세요", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "예: 수학, 영어" }

        let add = UIAlertAction(title: "추가", style: .default) { _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                self.normalTimers[name] = 0
                self.focusTimers[name] = 0
                self.addSubjectRow(subject: name)
                self.updateTimersDisplay()
                self.saveTimersToUserDefaults()
            }
        }

        alert.addAction(add)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    func addSubjectRow(subject: String) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.distribution = .fill

        let label = UILabel()
        label.text = subject
        label.font = .systemFont(ofSize: 16)
        label.widthAnchor.constraint(equalToConstant: 60).isActive = true

        let button = UIButton(type: .system)
        button.setTitle("▶", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(.systemBlue, for: .normal)
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true

        let timeLabel = UILabel()
        timeLabel.text = "00:00:00"
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        timeLabel.textColor = .darkGray

        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("❌", for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 16)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.widthAnchor.constraint(equalToConstant: 30).isActive = true

        button.addAction(UIAction { _ in
            self.handlePlayButton(subject: subject, labelToUpdate: timeLabel)
        }, for: .touchUpInside)

        deleteButton.addAction(UIAction { _ in
            self.normalTimers.removeValue(forKey: subject)
            self.focusTimers.removeValue(forKey: subject)
            if self.currentRunningSubject == subject {
                self.mainTimer?.invalidate()
                self.currentRunningSubject = nil
            }
            self.outerStackView.removeArrangedSubview(row)
            row.removeFromSuperview()
            self.updateTotalTime()
            self.saveTimersToUserDefaults()
        }, for: .touchUpInside)

        row.addArrangedSubview(label)
        row.addArrangedSubview(button)
        row.addArrangedSubview(timeLabel)
        row.addArrangedSubview(deleteButton)

        let index = outerStackView.arrangedSubviews.count - 1
        outerStackView.insertArrangedSubview(row, at: index)
    }

    func handlePlayButton(subject: String, labelToUpdate: UILabel) {
        if currentRunningSubject == subject {
            mainTimer?.invalidate()
            mainTimer = nil
            currentRunningSubject = nil
            startTimerMode = nil

         
            updatePlayButtonUI(for: subject, isPlaying: false)
        } else {
            mainTimer?.invalidate()
            updatePlayButtonUI(for: currentRunningSubject, isPlaying: false) // 이전 버튼 정지

            currentRunningSubject = subject
            startTimerMode = selectedMode

            if selectedMode == .focus {
                startMotionDetection()
            }

         
            updatePlayButtonUI(for: subject, isPlaying: true)

            mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if self.startTimerMode == .normal {
                    self.normalTimers[subject, default: 0] += 1
                } else {
                    self.focusTimers[subject, default: 0] += 1
                }
                self.updateTimersDisplay()
                self.updateTotalTime()
                self.saveTimeForToday(subject: subject, seconds: 1, mode: self.startTimerMode ?? .normal)
                self.saveTimersToUserDefaults()
            }
        }
    }
    func updatePlayButtonUI(for subject: String?, isPlaying: Bool) {
        guard let subject = subject else { return }

        for view in outerStackView.arrangedSubviews {
            guard let row = view as? UIStackView, row.arrangedSubviews.count >= 2 else { continue }
            let label = row.arrangedSubviews[0] as? UILabel
            let button = row.arrangedSubviews[1] as? UIButton
            if label?.text == subject {
                button?.setTitle(isPlaying ? "■" : "▶", for: .normal)
                break
            }
        }
    }


    func updateTimersDisplay() {
        for view in outerStackView.arrangedSubviews {
            guard let row = view as? UIStackView, row.arrangedSubviews.count >= 3 else { continue }
            let subjectLabel = row.arrangedSubviews[0] as? UILabel
            let timeLabel = row.arrangedSubviews[2] as? UILabel
            guard let subject = subjectLabel?.text else { continue }
            let seconds = (selectedMode == .normal ? normalTimers[subject] : focusTimers[subject]) ?? 0
            let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
            timeLabel?.text = String(format: "%02d:%02d:%02d", h, m, s)
        }
    }

    func updateTotalTime() {
        let totalSeconds = normalTimers.values.reduce(0, +) + focusTimers.values.reduce(0, +)
        let h = totalSeconds / 3600, m = (totalSeconds % 3600) / 60, s = totalSeconds % 60
        totalTimeLabel.text = String(format: "%02d:%02d:%02d", h, m, s)

        if let target = alertSeconds, totalSeconds >= target, !isAlertTriggered {
            isAlertTriggered = true
            showAlertForTime()
        }
    }

    func showAlertForTime() {
        guard let alertSeconds = alertSeconds else { return }
        let minutes = alertSeconds / 60
        let message = minutes < 1
            ? "\(alertSeconds)초가 지났어요!"
            : "\(minutes)분이 지났어요!"

        let alert = UIAlertController(title: "⏰ 알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @IBAction func setAlertTimeTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "알림 시간 설정", message: "분 단위로 입력하세요 (예: 1)", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "예: 1"
            if let current = self.alertSeconds {
                textField.text = "\(current / 60)"
            }
            textField.keyboardType = .numberPad
        }

        let confirm = UIAlertAction(title: "설정", style: .default) { _ in
            if let text = alert.textFields?.first?.text,
               let minutes = Int(text), minutes > 0 {
                self.alertSeconds = minutes * 60
                self.isAlertTriggered = false
            }
        }

        alert.addAction(confirm)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    @IBAction func soundButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "백색소음 선택", message: "사운드를 선택하세요", preferredStyle: .actionSheet)
        let sounds = ["비", "불", "사막바람", "강한바람", "바람"]

        for sound in sounds {
            alert.addAction(UIAlertAction(title: sound, style: .default) { _ in
                self.playSound(named: sound)
            })
        }

        alert.addAction(UIAlertAction(title: "끄기", style: .destructive) { _ in
            self.audioPlayer?.stop()
            self.selectedSoundName = nil
            self.updateSoundButtonIcon()
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    func playSound(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("사운드 파일 경로를 찾을 수 없음: \(name).mp3")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            selectedSoundName = name
            updateSoundButtonIcon()
        } catch {
            print("사운드 재생 실패: \(error)")
        }
    }

    func updateSoundButtonIcon() {
        let imageName = selectedSoundName == nil ? "speaker.slash" : "speaker.wave.2.fill"
        soundButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func saveTimeForToday(subject: String, seconds: Int, mode: TimerMode) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        let today = getTodayString()

        var fullData = UserDefaults.standard.dictionary(forKey: "studyData") as? [String: Any] ?? [:]
        var userData = fullData[userId] as? [String: Any] ?? [:]

        var modeData = userData[mode == .normal ? "normal" : "focus"] as? [String: [String: NSNumber]] ?? [:]
        var dateData = modeData[today] ?? [:]
        let previous = dateData[subject]?.intValue ?? 0
        dateData[subject] = NSNumber(value: previous + seconds)
        modeData[today] = dateData
        userData[mode == .normal ? "normal" : "focus"] = modeData

        let hour = Calendar.current.component(.hour, from: Date())
        var hourlyData = userData["hourly"] as? [String: [String: NSNumber]] ?? [:]
        var todayHourly = hourlyData[today] ?? [:]
        let prevHourSeconds = todayHourly["\(hour)"]?.intValue ?? 0
        todayHourly["\(hour)"] = NSNumber(value: prevHourSeconds + seconds)
        hourlyData[today] = todayHourly
        userData["hourly"] = hourlyData

        fullData[userId] = userData
        UserDefaults.standard.set(fullData, forKey: "studyData")
    }

    func saveTimersToUserDefaults() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        let data: [String: Any] = [
            "normal": normalTimers,
            "focus": focusTimers
        ]
        UserDefaults.standard.set(data, forKey: "persistentTimers_\(userId)")
    }

    func loadTimersFromUserDefaults() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        guard let data = UserDefaults.standard.dictionary(forKey: "persistentTimers_\(userId)") else { return }

        if let normal = data["normal"] as? [String: Int] {
            normalTimers = normal
        }
        if let focus = data["focus"] as? [String: Int] {
            focusTimers = focus
        }

        for subject in Set(normalTimers.keys).union(focusTimers.keys) {
            addSubjectRow(subject: subject)
        }
    }
}

