// RegisterViewController.swift
import UIKit

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var idField: UITextField!
    @IBOutlet weak var pwField: UITextField!
    @IBOutlet weak var pwConfirmField: UITextField!
    
    @IBAction func registerTapped(_ sender: UIButton) {
        guard let id = idField.text, !id.isEmpty,
              let pw = pwField.text, !pw.isEmpty,
              let pwConfirm = pwConfirmField.text, pw == pwConfirm else {
            showAlert("입력 오류", "모든 항목을 정확히 입력해주세요.")
            return
        }
        
        UserDefaults.standard.set(id, forKey: "userId")
        UserDefaults.standard.set(pw, forKey: "userPw")
        
        showAlert("성공", "회원가입이 완료되었습니다.") {
            self.dismiss(animated: true)
        }
    }
    
    func showAlert(_ title: String, _ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

