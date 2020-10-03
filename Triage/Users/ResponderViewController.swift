//
//  ResponderViewController.swift
//  Triage
//
//  Created by Francis Li on 10/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class ResponderViewController: UIViewController {
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var imageView: RoundImageView!
    @IBOutlet weak var transferButton: FormButton!
    @IBOutlet weak var firstNameField: FormField!
    @IBOutlet weak var lastNameField: FormField!
    @IBOutlet weak var positionField: FormField!
    @IBOutlet weak var agencyField: FormField!

    var user: User!
    var agency: Agency?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let sceneId = AppSettings.sceneId else { return }
        guard let scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId) else { return }

        if let imageURL = user.iconUrl {
            imageView.imageURL = imageURL
        } else {
            imageView.backgroundColor = .greyPeakBlue
            imageView.image = UIImage(named: "User")
        }

        if scene.incidentCommanderId == user.id {
            transferButton.isHidden = true
        }

        firstNameField.text = user.firstName
        lastNameField.text = user.lastName
        positionField.text = user.position
        if let agency = agency {
            agencyField.text = agency.name
        } else {
            agencyField.isHidden = true
        }
    }
}
