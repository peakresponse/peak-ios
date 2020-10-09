//
//  ResponderViewController.swift
//  Triage
//
//  Created by Francis Li on 10/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

class ResponderViewController: UIViewController {
    @IBOutlet weak var imageView: RoundImageView!
    @IBOutlet weak var roleButton: RoleButton!
    @IBOutlet weak var transferButton: FormButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var agencyLabel: UILabel!
    @IBOutlet weak var roleDropdownView: UIView!
    @IBOutlet weak var triageButton: RoleButton!
    @IBOutlet weak var treatmentButton: RoleButton!
    @IBOutlet weak var stagingButton: RoleButton!
    @IBOutlet weak var transportButton: RoleButton!

    var roleButtons: [RoleButton] = []

    var responder: Responder!
    var responderNotificationToken: NotificationToken?
    var scene: Scene!
    var sceneNotificationToken: NotificationToken?

    deinit {
        responderNotificationToken?.invalidate()
        sceneNotificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let sceneId = AppSettings.sceneId else { return }
        scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId)
        sceneNotificationToken = scene.observe { [weak self] (change) in
            switch change {
            case .change:
                self?.configure()
            case .error(let error):
                self?.presentAlert(error: error)
            case .deleted:
                break
            }
        }

        responderNotificationToken = responder.observe { [weak self] (change) in
            switch change {
            case .change:
                self?.configure()
            case .error(let error):
                self?.presentAlert(error: error)
            case .deleted:
                break
            }
        }

        configure()
    }

    private func configure() {
        if let imageURL = responder.user?.iconUrl {
            imageView.imageURL = imageURL
        } else {
            imageView.backgroundColor = .greyPeakBlue
            imageView.image = UIImage(named: "User")
        }

        // configure role dropdown
        roleDropdownView.isHidden = true
        roleDropdownView.layer.borderWidth = 3
        roleDropdownView.layer.borderColor = UIColor.greyPeakBlue.cgColor
        roleButtons = [ triageButton, treatmentButton, stagingButton, transportButton ]
        for (i, roleButton) in roleButtons.enumerated() {
            roleButton.role = ResponderRole.allCases[i]
            roleButton.buttonLabel = roleButton.buttonLabel?.replacingOccurrences(of: " ", with: "\n")
            roleButton.button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -22)
        }

        // configure Role button
        if scene.incidentCommanderId == responder.user?.id {
            roleButton.isMGS = true
            roleButton.isSelected = true
            roleButton.isUserInteractionEnabled = false
        } else if let role = ResponderRole(rawValue: responder.role ?? "") {
            roleButton.role = role
            roleButton.isSelected = true
            roleButton.isUserInteractionEnabled = scene.incidentCommanderId == AppSettings.userId
            roleDropdownView.layer.borderColor = role.color.cgColor
        } else if scene.incidentCommanderId != AppSettings.userId {
            roleButton.isHidden = true
        }

        // configure Transfer MGS Role button
        transferButton.button.titleLabel?.numberOfLines = 0
        transferButton.button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 17, bottom: 0, right: 17)
        if responder.role == nil && scene.incidentCommanderId == AppSettings.userId {
            if scene.incidentCommanderId == responder.user?.id {
                transferButton.isHidden = true
            }
        } else {
            transferButton.isHidden = true
        }
        transferButton.isHidden = responder.role != nil ||
            scene.incidentCommanderId != AppSettings.userId ||
            scene.incidentCommanderId == responder.user?.id

        // configure info labels
        nameLabel.text = responder.user?.fullName
        positionLabel.text = responder.user?.position
        if let agency = responder.agency {
            agencyLabel.text = agency.name
        } else {
            agencyLabel.isHidden = true
        }
    }

    @IBAction func assignPressed(_ sender: Any) {
        roleDropdownView.isHidden = !roleDropdownView.isHidden
    }

    @IBAction func rolePressed(_ sender: Any) {
        if let index = roleButtons.firstIndex(where: { $0.button.isEqual(sender) }) {
            let role = ResponderRole.allCases[index]
            AppRealm.assignResponder(responderId: responder.id, role: role) { (error) in
                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        self?.presentAlert(error: error)
                    }
                }
            }
        }
        roleDropdownView.isHidden = true
    }

    @IBAction func transferPressed(_ sender: Any) {
        let vc = AlertViewController()
        vc.alertTitle = String(format: "TransferCommandConfirmation.title".localized, responder.user?.fullName ?? "")
        vc.alertMessage = "TransferCommandConfirmation.message".localized
        vc.addAlertAction(title: "Button.cancel".localized, style: .cancel, handler: nil)
        vc.addAlertAction(title: "Button.transfer".localized, style: .default) { [weak self] (_) in
            guard let self = self, let sceneId = AppSettings.sceneId,
                  let userId = self.responder.user?.id, let agencyId = self.responder.agency?.id else { return }
            AppRealm.transferScene(sceneId: sceneId, userId: userId, agencyId: agencyId, completionHandler: { (error) in
                DispatchQueue.main.async { [weak self] in
                    if let error = error {
                        self?.presentAlert(error: error)
                    } else {
                        self?.transferButton.isHidden = true
                        self?.dismissAnimated()
                    }
                }
            })
        }
        presentAnimated(vc)
    }
}
