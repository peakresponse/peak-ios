//
//  TriageHeaderCell.swift
//  Triage
//
//  Created by Francis Li on 5/10/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit

class TriageHeaderCell: UICollectionViewCell {
    weak var headerLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.textColor = .text
        headerLabel.font = .h3SemiBold
        contentView.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            headerLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            headerLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: headerLabel.bottomAnchor)
        ])
        self.headerLabel = headerLabel
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
