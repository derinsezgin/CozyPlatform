//
//  SignInViewController.swift
//  CozyPlatform
//
//  Created by DERİN SEZGİN on 19.10.2020.
//

import UIKit

class SignInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usrnameTxtFld: UITextField!
    @IBOutlet weak var passwordTxtFld: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var signUpBtn: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // text field's delegate
        self.usrnameTxtFld.delegate = self
        self.passwordTxtFld.delegate = self
        
        // IBOutlet's borderwidth, bordercolor and radius settings
        self.usrnameTxtFld.layer.borderWidth = 0.5
        self.usrnameTxtFld.layer.borderColor = UIColor.black.cgColor
        self.usrnameTxtFld.layer.cornerRadius = 15
        
        self.passwordTxtFld.layer.borderWidth = 0.5
        self.passwordTxtFld.layer.borderColor = UIColor.black.cgColor
        self.passwordTxtFld.layer.cornerRadius = 15
        
        self.loginBtn.layer.borderWidth = 0.5
        self.loginBtn.layer.borderColor = UIColor.black.cgColor
        self.loginBtn.layer.cornerRadius = 15
        self.loginBtn.isEnabled = false
        self.loginBtn.backgroundColor = .lightGray
        
        self.signUpBtn.layer.borderWidth = 0.5
        self.signUpBtn.layer.borderColor = UIColor.black.cgColor
        self.signUpBtn.layer.cornerRadius = 15
    
        // local notification when keyboard show
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        // local notification when keyboard hide
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // to dismiss keyboard when clicking any point on view (except keyboard)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        // to dismiss keyboard when clicking any point on view (except keyboard)
           view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // hide navigation bar on login and signup pages
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //dismiss keyboard when come back from sign up view
        view.endEditing(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // show navigation bar
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
    
    // check if user can login when any textfield changes
    func textFieldDidChangeSelection(_ textField: UITextField) {
        
        if usrnameTxtFld.text!.count >= 7 && passwordTxtFld.text!.count >= 6  {
            self.loginBtn.isEnabled = true
            self.loginBtn.backgroundColor = .systemTeal
        } else {
            self.loginBtn.isEnabled = false
            self.loginBtn.backgroundColor = .lightGray
        }
    }
    
    
    @IBAction func signn(_ sender: UIButton) {
        
        // hide keyboard before go to sign screen
        view.endEditing(true)
        
        // firebase; login with FirebaseAuthManager
        
        let loginManager = FirebaseAuthManager()
           guard let email = usrnameTxtFld.text, let password = passwordTxtFld.text else { return }
           loginManager.signIn(email: email, pass: password) {[weak self] (success) in
            guard self != nil else { return }
               if (success) {
                self!.performSegue(withIdentifier: "userLogged", sender: nil)
               } else {
                self!.showSingleAlert(withMessage: "There was an error. Please check username, password and repeat password fields.")
               }

           }
    }
    
    // single alert func
    func showSingleAlert(withMessage message: String) {
        let alertController = UIAlertController(title: "Cozy Platform", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

}
