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

class LoginViewController: UIViewController, FormFieldDelegate {
    @IBOutlet weak var loginFormView: UIView!
    @IBOutlet weak var emailField: FormField!
    @IBOutlet weak var passwordField: FormField!
    @IBOutlet weak var loginButton: FormButton!
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    weak var loginDelegate: LoginViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        isModal = true

        emailField.textField.keyboardType = .emailAddress
        emailField.textField.autocorrectionType = .no
        emailField.textField.autocapitalizationType = .none
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = emailField.becomeFirstResponder()
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    @IBAction func loginPressed(_ sender: FormButton) {
        let email = emailField.text
        let password = passwordField.text
        if let email = email, let password = password, !email.isEmpty && !password.isEmpty {
            emailField.isEnabled = false
            passwordField.isEnabled = false
            loginButton.isEnabled = false
            activityView.startAnimating()
            let task = ApiClient.shared.login(email: email, password: password) { [weak self] (data, error) in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.activityView.stopAnimating()
                    if let error = error {
                        if let error = error as? ApiClientError, error == .unauthorized {
                            self.presentAlert(title: "Error.title".localized, message: "Invalid email and/or password.".localized)
                        } else {
                            self.presentAlert(error: error)
                        }
                    } else if let data = data, let agencies = data["agencies"] as? [[String: Any]], agencies.count > 0 {
                        if agencies.count > 1 {
                            // TODO navigate to a selection screen
                            self.presentAlert(title: "Error.title".localized, message: "Error.unexpected".localized)
                        }
                        if let subdomain = agencies[0]["subdomain"] as? String {
                            AppSettings.subdomain = subdomain
                            AppRealm.me { [weak self] (user, agency, scene, error) in
                                let userId = user?.id
                                let agencyId = agency?.id
                                let sceneId = scene?.id
                                DispatchQueue.main.async { [weak self] in
                                    guard let self = self else { return }
                                    if let error = error {
                                        self.presentAlert(error: error)
                                    } else if let userId = userId, let agencyId = agencyId {
                                        AppSettings.login(userId: userId, agencyId: agencyId, sceneId: sceneId)
                                        if let sceneId = sceneId {
                                            AppDelegate.enterScene(id: sceneId)
                                        } else {
                                            AppRealm.connect()
                                        }
                                        self.loginDelegate?.loginViewControllerDidLogin?(self)
                                    } else {
                                        self.presentAlert(title: "Error.title".localized, message: "Error.unexpected".localized)
                                    }
                                }
                            }
                        } else {
                            self.presentAlert(title: "Error.title".localized, message: "Error.unexpected".localized)
                        }
                    } else {
                        self.presentAlert(title: "Error.title".localized, message: "Error.unexpected".localized)
                    }
                    self.emailField.isEnabled = true
                    self.passwordField.isEnabled = true
                    self.loginButton.isEnabled = true
                }
            }
            task.resume()
        }
    }

    // MARK: - FormFieldDelegate

    func formFieldShouldReturn(_ field: BaseField) -> Bool {
        if field == emailField {
            _ = passwordField.becomeFirstResponder()
        } else if field == passwordField {
            _ = passwordField.resignFirstResponder()
            loginPressed(loginButton)
        }
        return false
    }
}
