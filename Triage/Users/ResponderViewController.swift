//
//  ResponderViewController.swift
//  Triage
//
//  Created by Francis Li on 10/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class ResponderViewController: UIViewController {
    @IBOutlet weak var imageView: RoundImageView!
    @IBOutlet weak var roleButton: RoleButton!
    @IBOutlet weak var transferButton: FormButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var agencyLabel: UILabel!

    var responder: Responder!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let sceneId = AppSettings.sceneId else { return }
        guard let scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId) else { return }

        if let imageURL = responder.user?.iconUrl {
            imageView.imageURL = imageURL
        } else {
            imageView.backgroundColor = .greyPeakBlue
            imageView.image = UIImage(named: "User")
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

        nameLabel.text = responder.user?.fullName
        positionLabel.text = responder.user?.position
        if let agency = responder.agency {
            agencyLabel.text = agency.name
        } else {
            agencyLabel.isHidden = true
        }
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
