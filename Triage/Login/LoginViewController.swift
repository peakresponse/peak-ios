//
//  LoginViewController.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

@objc protocol LoginViewControllerDelegate {
    @objc optional func loginViewControllerDidLogin(_ vc: LoginViewController)
}

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    weak var loginDelegate: LoginViewControllerDelegate?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        emailField.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            passwordField.resignFirstResponder()
            loginPressed(loginButton)
        }
        return true
    }
    
    @IBAction func loginPressed(_ sender: UIButton) {
        let email = emailField.text
        let password = passwordField.text
        if let email = email, let password = password {
            emailField.isEnabled = false
            passwordField.isEnabled = false
            loginButton.isEnabled = false
            activityView.startAnimating()
            let task = ApiClient.shared.login(email: email, password: password) { [weak self] (error) in
                DispatchQueue.main.async { [weak self] in
                    self?.activityView.stopAnimating()
                    if let error = error {
                        self?.presentAlert(error: error)
                    } else if let self = self {
                        self.loginDelegate?.loginViewControllerDidLogin?(self)
                    }
                }
            }
            task.resume()
        }
    }
}
