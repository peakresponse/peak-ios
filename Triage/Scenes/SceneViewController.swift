//
//  SceneViewController.swift
//  Triage
//
//  Created by Francis Li on 3/14/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

class SceneViewController: UIViewController, PRKit.FormFieldDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!

    func initSceneCommandHeader() {
        commandHeader.isUserHidden = false
        commandHeader.isSearchHidden = false
        commandHeader.searchField.returnKeyType = .done
        commandHeader.searchField.delegate = self
    }

    func performQuery() {

    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        performQuery()
    }

    func formFieldShouldBeginEditing(_ field: PRKit.FormField) -> Bool {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            for subview in commandHeader.stackView.arrangedSubviews {
                if subview != field {
                    subview.isHidden = true
                }
            }
        }
        return true
    }

    func formFieldShouldReturn(_ field: PRKit.FormField) -> Bool {
        field.resignFirstResponder()
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            for subview in commandHeader.stackView.arrangedSubviews {
                if subview != field {
                    subview.isHidden = false
                }
            }
        }
        return false
    }
}
