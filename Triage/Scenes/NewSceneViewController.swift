//
//  NewSceneViewController.swift
//  Triage
//
//  Created by Francis Li on 9/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class NewSceneViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var locationView: SceneLocationView!
    @IBOutlet weak var nameField: FormField!
    @IBOutlet weak var descField: FormField!
    @IBOutlet weak var approxPatientsField: FormField!
    @IBOutlet weak var urgencyField: FormField!

    var fields: [FormField]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fields = [nameField, descField, approxPatientsField, urgencyField]
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
