import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var registerLabel: UILabel!
    @IBOutlet weak var idField: UITextField!
    @IBOutlet weak var pwField: UITextField!
    
    @IBAction func loginTapped(_ sender: UIButton) {
        let savedId = UserDefaults.standard.string(forKey: "userId")
        let savedPw = UserDefaults.standard.string(forKey: "userPw")
        
        guard idField.text == savedId, pwField.text == savedPw else {
            showAlert("실패", "아이디 또는 비밀번호가 틀렸습니다.")
            return
        }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarVC = sb.instantiateViewController(identifier: "MainTabBarController") as? UITabBarController {
            tabBarVC.modalPresentationStyle = .fullScreen
            present(tabBarVC, animated: true)
        }
    }
    
    func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @IBAction func goToRegister(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let registerVC = sb.instantiateViewController(identifier: "RegisterViewController")
        self.navigationController?.pushViewController(registerVC, animated: true)

    }
}

