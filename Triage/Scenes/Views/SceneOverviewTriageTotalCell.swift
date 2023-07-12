//
//  SceneOverviewTriageTotalCell.swift
//  Triage
//
//  Created by Francis Li on 5/10/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit

class SceneOverviewTriageTotalCell: UICollectionViewCell {
    @IBOutlet weak var headerLabel: UILabel!

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        var frame = attributes.frame
        if traitCollection.horizontalSizeClass == .compact {
            frame.size.width = UIScreen.main.bounds.width - 40
        }
        attributes.frame = frame
        return attributes
    }
}
