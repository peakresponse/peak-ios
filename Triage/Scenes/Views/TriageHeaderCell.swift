//
//  TriageHeaderCell.swift
//  Triage
//
//  Created by Francis Li on 5/10/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit

class TriageHeaderCell: UICollectionViewCell {
    @IBOutlet weak var headerLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.textColor = .text
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let width = UIScreen.main.bounds.width - 40
        if attributes.frame.size.width < width {
            attributes.frame.size.width = width
        }
        return attributes
    }
}
