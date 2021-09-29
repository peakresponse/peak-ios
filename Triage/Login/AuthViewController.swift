//
//  AuthViewController.swift
//  Triage
//
//  Created by Francis Li on 9/29/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import Keyboardy

class AuthViewController: UIViewController, KeyboardStateDelegate {
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
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
