//
//  AuthViewController.swift
//  Triage
//
//  Created by Francis Li on 9/29/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import Keyboardy
import PRKit

@objc protocol AuthViewControllerDelegate {
    @objc optional func authViewControllerDidLogin(_ vc: AuthViewController)
}

class AuthViewController: UIViewController, PRKit.FormFieldDelegate, KeyboardStateDelegate {
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var emailField: PRKit.TextField!
    @IBOutlet weak var passwordField: PRKit.PasswordField!
    @IBOutlet weak var signInButton: PRKit.Button!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    weak var delegate: AuthViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.textView.keyboardType = .emailAddress
        emailField.textView.autocorrectionType = .no
        emailField.textView.autocapitalizationType = .none
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)

        _ = emailField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
    }

    @IBAction func signInPressed(_ sender: PRKit.Button) {
        let email = emailField.text
        let password = passwordField.text
        if let email = email, let password = password, !email.isEmpty && !password.isEmpty {
            emailField.isUserInteractionEnabled = false
            passwordField.isUserInteractionEnabled = false
            signInButton.isUserInteractionEnabled = false
            activityIndicatorView.startAnimating()
            let task = ApiClient.shared.login(email: email, password: password) { [weak self] (data, error) in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.activityIndicatorView.stopAnimating()
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
                                        // check if the user or scene has changed since last login
                                        if userId != AppSettings.userId || sceneId != AppSettings.sceneId {
                                            // set new login ids, and navigate as needed
                                            AppSettings.login(userId: userId, agencyId: agencyId, sceneId: sceneId)
                                            if let sceneId = sceneId {
                                                AppDelegate.enterScene(id: sceneId)
                                            } else {
                                                _ = AppDelegate.leaveScene()
                                            }
                                        } else {
                                            self.delegate?.authViewControllerDidLogin?(self)
                                        }
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
                    self.emailField.isUserInteractionEnabled = true
                    self.passwordField.isUserInteractionEnabled = true
                    self.signInButton.isUserInteractionEnabled = true
                }
            }
            task.resume()
        }
    }

    // MARK: - FormFieldDelegate

    func formFieldShouldReturn(_ field: PRKit.FormField) -> Bool {
        if field == emailField {
            _ = passwordField.becomeFirstResponder()
        } else if field == passwordField {
            _ = passwordField.resignFirstResponder()
            signInPressed(signInButton)
        }
        return false
    }

    // MARK: - KeyboardStateDelegate

    public func keyboardWillTransition(_ state: KeyboardState) {
    }

    public func keyboardTransitionAnimation(_ state: KeyboardState) {
        switch state {
        case .activeWithHeight(let height):
            scrollViewBottomConstraint.constant = -height
        case .hidden:
            scrollViewBottomConstraint.constant = 0
        }
        view.layoutIfNeeded()
    }

    public func keyboardDidTransition(_ state: KeyboardState) {
    }
}
