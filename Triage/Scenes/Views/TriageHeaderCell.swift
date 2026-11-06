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
            headerLabel.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 6),
            headerLabel.leftAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leftAnchor),
            headerLabel.rightAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: headerLabel.bottomAnchor)
        ])
        self.headerLabel = headerLabel
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        var view = superview
        while !(view?.isKind(of: UICollectionView.self) ?? true) {
            view = view?.superview
        }
        if let collectionView = view as? UICollectionView,
           let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
           let inset = delegate.collectionView?(collectionView, layout: collectionView.collectionViewLayout, insetForSectionAt: 0) {
            let bounds = collectionView.bounds
            attributes.frame.size.width = bounds.size.width - inset.left - inset.right
        }
        return attributes
    }
}
