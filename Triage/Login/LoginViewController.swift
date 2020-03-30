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
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var loginFormView: UIView!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    weak var loginDelegate: LoginViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // add gradient background
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red: 0.757, green: 0.867, blue: 0.867, alpha: 1).cgColor,
            UIColor(red: 0.396, green: 0.702, blue: 0.855, alpha: 1).cgColor,
            UIColor(red: 0.275, green: 0.647, blue: 0.859, alpha: 1).cgColor,
            UIColor(red: 0.184, green: 0.494, blue: 0.667, alpha: 1).cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0.25, y: 0.25)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        view.layer.insertSublayer(gradient, at: 0)
            
        // add drop shadow to icon
        iconView.addShadow(withOffset: CGSize(width: 0, height: 4), radius: 4, color: UIColor.black, opacity: 0.1)

        // style login form card
        loginFormView.layer.cornerRadius = 6
        loginFormView.addShadow(withOffset: CGSize(width: 0, height: 4), radius: 4, color: UIColor.black, opacity: 0.1)
    }

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
                        if let error = error as? ApiClientError, error == .unauthorized {
                            self?.presentAlert(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Invalid email and/or password.", comment: ""))
                        } else {
                            self?.presentAlert(error: error)
                        }
                        self?.emailField.isEnabled = true
                        self?.passwordField.isEnabled = true
                        self?.loginButton.isEnabled = true
                    } else if let self = self {
                        self.loginDelegate?.loginViewControllerDidLogin?(self)
                    }
                }
            }
            task.resume()
        }
    }
}
