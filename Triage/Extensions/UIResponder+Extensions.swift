//
//  UIResponder+Extensions.swift
//  Triage
//
//  Created by Francis Li on 10/31/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation
import UIKit

extension UIResponder {
    func addKeyboardListener() {
        let defaultNotificationCenter = NotificationCenter.default
        defaultNotificationCenter.addObserver(
            self, selector: #selector(keyboardWillShowInternal(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        defaultNotificationCenter.addObserver(
            self, selector: #selector(keyboardDidShowInternal(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        defaultNotificationCenter.addObserver(
            self, selector: #selector(keyboardWillHideInternal(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        defaultNotificationCenter.addObserver(
            self, selector: #selector(keyboardDidHideInternal(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    func removeKeyboardListener() {
        let defaultNotificationCenter = NotificationCenter.default
        defaultNotificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        defaultNotificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    func hideKeyboard() {

    }

    private var shouldDispatchKeyboardNotification: Bool {
        if let vc = self as? UIViewController, vc.presentedViewController != nil {
            return false
        }
        return true
    }

    @objc private func keyboardWillShowInternal(_ notification: NSNotification) {
        guard shouldDispatchKeyboardNotification else { return }
        keyboardWillShow(notification)
    }

    @objc private func keyboardDidShowInternal(_ notification: NSNotification) {
        guard shouldDispatchKeyboardNotification else { return }
        keyboardDidShow(notification)
    }

    @objc private func keyboardWillHideInternal(_ notification: NSNotification) {
        guard shouldDispatchKeyboardNotification else { return }
        keyboardWillHide(notification)
    }

    @objc private func keyboardDidHideInternal(_ notification: NSNotification) {
        guard shouldDispatchKeyboardNotification else { return }
        keyboardDidHide(notification)
    }

    @objc func keyboardWillShow(_ notification: NSNotification) {

    }

    @objc func keyboardDidShow(_ notification: NSNotification) {

    }

    @objc func keyboardWillHide(_ notification: NSNotification) {

    }

    @objc func keyboardDidHide(_ notification: NSNotification) {

    }
}
