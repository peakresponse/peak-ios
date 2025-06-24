//
//  AuthViewController.swift
//  Triage
//
//  Created by Francis Li on 9/29/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import LocalAuthentication
import UIKit
import Keyboardy
import PRKit

@objc protocol AuthViewControllerDelegate {
    @objc optional func authViewControllerDidLogin(_ vc: AuthViewController)
}

class AuthViewController: UIViewController, AssignmentViewControllerDelegate, PRKit.FormFieldDelegate, KeyboardAwareScrollViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var emailField: PRKit.TextField!
    @IBOutlet weak var passwordField: PRKit.PasswordField!
    @IBOutlet weak var rememberMeCheckbox: PRKit.Checkbox!
    @IBOutlet weak var signInButton: PRKit.Button!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var versionLabel: UILabel!

    weak var delegate: AuthViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.backgroundColor = .background
        versionLabel.text = AppSettings.version
        emailField.keyboardType = .emailAddress

        if let email = AppSettings.email {
            emailField.text = email
            rememberMeCheckbox.isChecked = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)
        if let email = AppSettings.email {
            let context = LAContext()
            context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
            if context.biometryType == .faceID || context.biometryType == .touchID {
                context.localizedCancelTitle = "AuthViewController.usePassword".localized
                context.touchIDAuthenticationAllowableReuseDuration = 60
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "AuthViewController.savePassword".localized) { [weak self] (_, error) in
                    DispatchQueue.main.async { [weak self] in
                        if error == nil {
                            let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                                        kSecAttrAccount as String: email,
                                                        kSecAttrServer as String: PRApiClient.shared.baseURL.absoluteString,
                                                        kSecMatchLimit as String: kSecMatchLimitOne,
                                                        kSecReturnAttributes as String: true,
                                                        kSecReturnData as String: true]
                            var item: CFTypeRef?
                            _ = SecItemCopyMatching(query as CFDictionary, &item)
                            if let item = item as? [String: Any],
                               let passwordData = item[kSecValueData as String] as? Data,
                               let password = String(data: passwordData, encoding: .utf8) {
                                self?.passwordField.text = password
                            }
                        }
                        if self?.passwordField.text?.isEmpty ?? true {
                            _ = self?.passwordField.becomeFirstResponder()
                        }
                    }
                }
                return
            }
        }
        if emailField.text?.isEmpty ?? true {
            _ = emailField.becomeFirstResponder()
        } else {
            _ = passwordField.becomeFirstResponder()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !(emailField.text?.isEmpty ?? true) {
            emailField.updateStyle()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
    }

    func logIn(data: [String: Any], agencies: [[String: Any]]) {
        if agencies.count > 1 {
            // TODO navigate to a selection screen
            activityIndicatorView.stopAnimating()
            presentUnexpectedErrorAlert()
        }
        if let subdomain = agencies[0]["subdomain"] as? String {
            AppSettings.subdomain = subdomain
            if let routedUrl = agencies[0]["routedUrl"] as? String {
                AppSettings.routedUrl = routedUrl
            }
            // update agency forms in the background
            AppRealm.getForms()
            // update code lists in the background
            AppRealm.getLists { (_) in
                // noop
            }
            AppRealm.me { [weak self] (user, agency, assignment, vehicle, scene, awsCredentials, error) in
                let userId = user?.id
                let regionId = agency?.regionId
                let agencyId = agency?.id
                let assignmentId = assignment?.id
                let vehicleId = vehicle?.id
                let sceneId = scene?.id
                AppSettings.awsCredentials = awsCredentials
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if let error = error {
                        self.activityIndicatorView.stopAnimating()
                        self.presentAlert(error: error)
                    } else if let userId = userId, let agencyId = agencyId {
                        // check if the user or scene has changed since last login
                        if userId != AppSettings.userId || sceneId != AppSettings.sceneId {
                            // set new login ids, and navigate as needed
                            AppSettings.login(userId: userId, regionId: regionId, agencyId: agencyId, assignmentId: assignmentId, vehicleId: vehicleId, sceneId: sceneId)
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
            activityIndicatorView.stopAnimating()
            presentUnexpectedErrorAlert()
        }
    }

    @IBAction func signInPressed(_ sender: PRKit.Button) {
        let email = emailField.text
        let password = passwordField.text
        if let email = email, let password = password, !email.isEmpty && !password.isEmpty {
            var isPromptForFaceID = false
            if rememberMeCheckbox.isChecked {
                isPromptForFaceID = AppSettings.email != email
                AppSettings.email = email
            } else {
                AppSettings.email = nil
                let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword]
                _ = SecItemDelete(query as CFDictionary)
            }
            AppSettings.save()
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
                        if isPromptForFaceID {
                            let context = LAContext()
                            context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
                            if context.biometryType == .none {
                                self.logIn(data: data, agencies: agencies)
                            } else if context.biometryType == .faceID || context.biometryType == .touchID {
                                context.localizedCancelTitle = "AuthViewController.usePassword".localized
                                context.touchIDAuthenticationAllowableReuseDuration = 60
                                let type = "AuthViewController.\(context.biometryType == .faceID ? "faceID" : "touchID")".localized
                                let prompt = UIAlertController(title: String(format: "AuthViewController.useBiometrics.title".localized, type),
                                                               message: String(format: "AuthViewController.useBiometrics.message".localized, type),
                                                               preferredStyle: .alert)
                                prompt.addAction(UIAlertAction(title: "Button.no".localized, style: .cancel, handler: { [weak self] (_) in
                                    self?.logIn(data: data, agencies: agencies)
                                }))
                                prompt.addAction(UIAlertAction(title: "Button.yes".localized, style: .default, handler: { [weak self] (_) in
                                    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "AuthViewController.savePassword".localized) { [weak self] (_, error) in
                                        DispatchQueue.main.async { [weak self] in
                                            if let error = error {
                                                self?.presentAlert(error: error) { [weak self] in
                                                    self?.logIn(data: data, agencies: agencies)
                                                }
                                            } else {
                                                let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                                                            kSecAttrAccount as String: email,
                                                                            kSecAttrServer as String: PRApiClient.shared.baseURL.absoluteString,
                                                                            kSecValueData as String: password.data(using: .utf8) as Any]
                                                var status = SecItemAdd(query as CFDictionary, nil)
                                                if status == errSecDuplicateItem {
                                                    status = SecItemUpdate(query as CFDictionary, query as CFDictionary)
                                                }
                                                if status != errSecSuccess {
                                                    self?.presentAlert(title: "Error.title".localized, message: "AuthViewController.useBiometrics.unexpectedError".localized) { [weak self] in
                                                        self?.logIn(data: data, agencies: agencies)
                                                    }
                                                } else {
                                                    self?.logIn(data: data, agencies: agencies)
                                                }
                                            }
                                        }
                                    }
                                }))
                                self.presentAnimated(prompt)
                            }
                        } else {
                            self.logIn(data: data, agencies: agencies)
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
