//
//  UIViewController+Extensions.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

extension UIViewController: LoginViewControllerDelegate {
    func presentAlert(error: Error) {
        presentAlert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription)
    }

    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func logout() {
        ApiClient.shared.logout { [weak self] in
            AppRealm.deleteAll()
            DispatchQueue.main.async { [weak self] in
                self?.presentLogin()
            }
        }
    }
    
    func presentLogin() {
        if let vc = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() as? LoginViewController {
            vc.loginDelegate = self
            present(vc, animated: true, completion: nil)
        }
    }

    // MARK: - LoginViewControllerDelegate
    
    func loginViewControllerDidLogin(_ vc: LoginViewController) {
        dismiss(animated: true, completion: nil)
    }
}
