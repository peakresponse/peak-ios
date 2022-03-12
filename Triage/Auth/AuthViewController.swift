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

class AuthViewController: UIViewController, AssignmentViewControllerDelegate, PRKit.FormFieldDelegate, KeyboardAwareScrollViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var emailField: PRKit.TextField!
    @IBOutlet weak var passwordField: PRKit.PasswordField!
    @IBOutlet weak var signInButton: PRKit.Button!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    weak var delegate: AuthViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.keyboardType = .emailAddress
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
            let task = PRApiClient.shared.login(email: email, password: password) { [weak self] (_, _, data, error) in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if let error = error {
                        self.activityIndicatorView.stopAnimating()
                        if let error = error as? ApiClientError, error == .unauthorized {
                            self.presentAlert(title: "Error.title".localized, message: "Invalid email and/or password.".localized)
                        } else {
                            self.presentAlert(error: error)
                        }
                    } else if let data = data, let agencies = data["agencies"] as? [[String: Any]], agencies.count > 0 {
                        if agencies.count > 1 {
                            // TODO navigate to a selection screen
                            self.activityIndicatorView.stopAnimating()
                            self.presentUnexpectedErrorAlert()
                        }
                        if let subdomain = agencies[0]["subdomain"] as? String {
                            AppSettings.subdomain = subdomain
                            // update code lists in the background
                            AppRealm.getLists { (_) in
                                // noop
                            }
                            AppRealm.me { [weak self] (user, agency, assignment, scene, awsCredentials, error) in
                                let userId = user?.id
                                let agencyId = agency?.id
                                let assignmentId = assignment?.id
                                let sceneId = scene?.id
                                AppSettings.awsCredentials = awsCredentials
                                // log in to RoutED API (TODO: parameterize based on agency settings)
                                REDApiClient.shared.login { (_, _, error) in
                                    if error == nil {
                                        REDRealm.connect()
                                    }
                                }.resume()
                                DispatchQueue.main.async { [weak self] in
                                    guard let self = self else { return }
                                    if let error = error {
                                        self.activityIndicatorView.stopAnimating()
                                        self.presentAlert(error: error)
                                    } else if let userId = userId, let agencyId = agencyId {
                                        // check if the user or scene has changed since last login
                                        if userId != AppSettings.userId || sceneId != AppSettings.sceneId {
                                            // set new login ids, and navigate as needed
                                            AppSettings.login(userId: userId, agencyId: agencyId, assignmentId: assignmentId, sceneId: sceneId)
                                            if assignmentId == nil {
                                                let vc = UIStoryboard(name: "Auth",
                                                                      bundle: nil).instantiateViewController(withIdentifier: "Assignment")
                                                if let vc = vc as? AssignmentViewController {
                                                    vc.delegate = self
                                                }
                                                self.presentAnimated(vc)
                                            } else if let sceneId = sceneId {
                                                AppDelegate.enterScene(id: sceneId)
                                            } else {
                                                _ = AppDelegate.leaveScene()
                                            }
                                        } else {
                                            self.delegate?.authViewControllerDidLogin?(self)
                                        }
                                    } else {
                                        self.activityIndicatorView.stopAnimating()
                                        self.presentUnexpectedErrorAlert()
                                    }
                                }
                            }
                        } else {
                            self.activityIndicatorView.stopAnimating()
                            self.presentUnexpectedErrorAlert()
                        }
                    } else {
                        self.activityIndicatorView.stopAnimating()
                        self.presentUnexpectedErrorAlert()
                    }
                    self.emailField.isUserInteractionEnabled = true
                    self.passwordField.isUserInteractionEnabled = true
                    self.signInButton.isUserInteractionEnabled = true
                }
            }
            task.resume()
        }
    }

    // MARK: - AssignmentViewControllerDelegate

    func assignmentViewController(_ vc: AssignmentViewController, didCreate assignmentId: String) {
        if let sceneId = AppSettings.sceneId {
            AppDelegate.enterScene(id: sceneId)
        } else {
            _ = AppDelegate.leaveScene()
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
}
