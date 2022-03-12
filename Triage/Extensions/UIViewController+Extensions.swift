//
//  UIViewController+Extensions.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

extension UIViewController: AuthViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    @IBInspectable var isModal: Bool {
        get {
            if #available(iOS 13.0, *) {
                return isModalInPresentation
            } else {
                return true
            }
        }
        set {
            if #available(iOS 13.0, *) {
                isModalInPresentation = newValue
            }
        }
    }

    func presentAlert(error: Error) {
        presentAlert(title: "Error.title".localized, message: error.localizedDescription)
    }

    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func presentUnexpectedErrorAlert() {
        presentAlert(title: "Error.title".localized, message: "Error.unexpected".localized)
    }

    func logout() {
        PRApiClient.shared.logout { [weak self] in
            AppRealm.disconnectScene()
            AppRealm.disconnect()
            AppRealm.deleteAll()
            AppSettings.logout()
            DispatchQueue.main.async { [weak self] in
                self?.presentLogin()
            }
        }
    }

    func presentLogin() {
        if let vc = UIStoryboard(name: "Auth", bundle: nil).instantiateInitialViewController() as? AuthViewController {
            vc.delegate = self
            presentAnimated(vc)
        }
    }

    func presentAnimated(_ vc: UIViewController) {
        if vc as? UIAlertController == nil {
            vc.presentationController?.delegate = self
        }
        present(vc, animated: true, completion: { [weak self] in
            self?.didPresentAnimated()
        })
    }

    @objc func didPresentAnimated() {

    }

    @IBAction func dismissAnimated() {
        dismiss(animated: true, completion: { [weak self] in
            self?.didDismissPresentation()
        })
    }

    @objc func didDismissPresentation() {

    }

    // MARK: - AuthViewControllerDelegate

    func authViewControllerDidLogin(_ vc: AuthViewController) {
        dismissAnimated()
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didDismissPresentation()
    }
}
