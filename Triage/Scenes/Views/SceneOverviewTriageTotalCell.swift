//
//  SceneOverviewTriageTotalCell.swift
//  Triage
//
//  Created by Francis Li on 5/10/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit

class SceneOverviewTriageTotalCell: UICollectionViewCell, SceneOverviewCell {
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        var frame = attributes.frame
        if traitCollection.horizontalSizeClass == .compact {
            frame.size.width = UIScreen.main.bounds.width - 40
        }
        attributes.frame = frame
        return attributes
    }

    func configure(from scene: Scene) {
        var count = 0
        if let approxPriorityPatientsCounts = scene.approxPriorityPatientsCounts {
            count = approxPriorityPatientsCounts[0..<5].reduce(count, { return $0 + $1 })
        }
        totalLabel.text = String(format: "SceneOverviewTriageTotalCell.totalLabel".localized, count)
    }
}
