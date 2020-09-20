//
//  UIViewController+Extensions.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

extension UIViewController: LoginViewControllerDelegate, UIAdaptivePresentationControllerDelegate {    
    func presentAlert(error: Error) {
        presentAlert(title: "Error".localized, message: error.localizedDescription)
    }

    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func logout() {
        ApiClient.shared.logout { [weak self] in
            AppRealm.deleteAll()
            AppSettings.logout()
            DispatchQueue.main.async { [weak self] in
                self?.presentLogin()
            }
        }
    }
    
    func presentLogin() {
        if let vc = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() as? LoginViewController {
            vc.loginDelegate = self
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
    
    @IBAction @objc func dismissAnimated() {
        dismiss(animated: true, completion: { [weak self] in
            self?.didDismissPresentation()
        })
    }
    
    @objc func didDismissPresentation() {
        
    }

    // MARK: - LoginViewControllerDelegate
    
    func loginViewControllerDidLogin(_ vc: LoginViewController) {
        dismissAnimated()
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didDismissPresentation()
    }
}
