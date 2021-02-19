//
//  SignUpViewController.swift
//  CozyPlatform
//
//  Created by DERİN SEZGİN on 19.10.2020.
//

import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usrnameTxtFld: UITextField!
    @IBOutlet weak var passwordTxtFld: UITextField!
    @IBOutlet weak var repeatPasswordTxtFld: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var signUpBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //text fields delegate
        self.usrnameTxtFld.delegate = self
        self.passwordTxtFld.delegate = self
        
        // IBOutlet's borderwidth, bordercolor and radius settings
        self.repeatPasswordTxtFld.delegate = self
        self.passwordTxtFld.textContentType = .oneTimeCode
        self.repeatPasswordTxtFld.textContentType = .oneTimeCode
        
        self.usrnameTxtFld.layer.borderWidth = 0.5
        self.usrnameTxtFld.layer.borderColor = UIColor.black.cgColor
        self.usrnameTxtFld.layer.cornerRadius = 15
        
        self.passwordTxtFld.layer.borderWidth = 0.5
        self.passwordTxtFld.layer.borderColor = UIColor.black.cgColor
        self.passwordTxtFld.layer.cornerRadius = 15
        
        self.repeatPasswordTxtFld.layer.borderWidth = 0.5
        self.repeatPasswordTxtFld.layer.borderColor = UIColor.black.cgColor
        self.repeatPasswordTxtFld.layer.cornerRadius = 15
        
        self.loginBtn.layer.borderWidth = 0.5
        self.loginBtn.layer.borderColor = UIColor.black.cgColor
        self.loginBtn.layer.cornerRadius = 15
        
        self.signUpBtn.layer.borderWidth = 0.5
        self.signUpBtn.layer.borderColor = UIColor.black.cgColor
        self.signUpBtn.layer.cornerRadius = 15
        self.signUpBtn.isEnabled = false
        self.signUpBtn.backgroundColor = .lightGray

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    
    @objc func dismissKeyboard() {
           view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @IBAction func dismiss(_ sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        
        if (usrnameTxtFld.text!.count > 0 && passwordTxtFld.text!.count >= 6 || repeatPasswordTxtFld.text!.count >= 6) && passwordTxtFld.text == repeatPasswordTxtFld.text {
  
            self.signUpBtn.isEnabled = true
            self.signUpBtn.backgroundColor = hexStringToUIColor(hex: "#F9F100")
        } else {
            self.signUpBtn.isEnabled = false
            self.signUpBtn.backgroundColor = .lightGray
        }
    }
    
    @IBAction func signup(_ sender: UIButton) {
        
        view.endEditing(true)
        
        let signUpManager = FirebaseAuthManager()
            if let email = usrnameTxtFld.text, let password = passwordTxtFld.text {
                signUpManager.createUser(email: email, password: password) {[weak self] (success) in
                    guard self != nil else { return }
 
                    if (success) {

                        let alert = UIAlertController(title: "Cozy Platform", message: "User was sucessfully created.", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
                                self!.performSegue(withIdentifier: "userCreated", sender: nil)
                            }))
                            
                        self!.present(alert, animated: true, completion: nil)
                        
                    } else {
                        self!.showSingleAlert(withMessage: "There was an error. Please check username and password fields. Password must be 6 characters long or more")
                    }
                }
            }
    }
    

    func showSingleAlert(withMessage message: String) {
        let alertController = UIAlertController(title: "Cozy Platform", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

}

// helper func. to use hex color code on swift
func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }

    if ((cString.count) != 6) {
        return UIColor.gray
    }

    var rgbValue:UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}
