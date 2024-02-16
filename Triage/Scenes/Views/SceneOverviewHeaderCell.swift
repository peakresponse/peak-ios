//
//  SceneOverviewHeaderCell.swift
//  Triage
//
//  Created by Francis Li on 5/4/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit
import PRKit

class SceneOverviewHeaderCell: UICollectionViewCell, SceneOverviewCell {
    @IBOutlet weak var incidentNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var closeButton: PRKit.Button!
    @IBOutlet weak var editButton: PRKit.Button!

    func configure(from scene: Scene) {
        if let incident = scene.incident.first {
            incidentNumberLabel.text = "#\(incident.number ?? "")"
        }
        addressLabel.text = scene.address
        timestampLabel.text = scene.createdAt?.asDateTimeString()
        if scene.mgsResponder?.user?.id == AppSettings.userId {
            closeButton.setTitle("Button.closeScene".localized, for: .normal)
        } else if scene.isResponder(userId: AppSettings.userId) {
            closeButton.setTitle("Button.leaveScene".localized, for: .normal)
        } else {
            closeButton.setTitle("Button.exitScene".localized, for: .normal)
        }
    }
}
