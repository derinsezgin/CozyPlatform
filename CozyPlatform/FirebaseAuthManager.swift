//
//  FirebaseAuthManager.swift
//  CozyPlatform
//
//  Created by DERİN SEZGİN on 19.10.2020.
//

import FirebaseAuth
import UIKit

class FirebaseAuthManager {
    
    // firebase: create user
    func createUser(email: String, password: String, completionBlock: @escaping (_ success: Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) {(authResult, error) in
            if (authResult?.user) != nil {
                completionBlock(true)
            } else {
                completionBlock(false)
                print(error!.localizedDescription)
            }
        }
    }
    
    // firebase: sign user
    func signIn(email: String, pass: String, completionBlock: @escaping (_ success: Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: pass) { (result, error) in
            if let error = error, let _ = AuthErrorCode(rawValue: error._code) {
                completionBlock(false)
                print(error.localizedDescription)
            } else {
                completionBlock(true)
                
            }
        }
    }
}
