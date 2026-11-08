//
//  ReunifyCollectionViewCell.swift
//  Triage
//
//  Created by Francis Li on 3/12/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

class ReunifyCollectionViewCell: UICollectionViewCell {
    weak var reportField: TransportCartReportField!
    weak var responderField: TransportCartResponderField!
    weak var facilityField: TransportCartFacilityField!
    weak var updatedAtLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        backgroundColor = .background

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .highlight
        self.selectedBackgroundView = selectedBackgroundView

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16)
        ])

        let reportField = TransportCartReportField()
        reportField.disclosureIndicatorView.widthAnchor.constraint(equalToConstant: 0).isActive = true
        reportField.isUserInteractionEnabled = false
        stackView.addArrangedSubview(reportField)
        self.reportField = reportField

        let responderField = TransportCartResponderField()
        responderField.disclosureIndicatorView.widthAnchor.constraint(equalToConstant: 0).isActive = true
        responderField.isUserInteractionEnabled = false
        stackView.addArrangedSubview(responderField)
        self.responderField = responderField

        let facilityField = TransportCartFacilityField()
        facilityField.isUserInteractionEnabled = false
        stackView.addArrangedSubview(facilityField)
        self.facilityField = facilityField

        let view = UIView()
        stackView.addArrangedSubview(view)

        let updatedAtLabel = UILabel()
        updatedAtLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedAtLabel.font = .body14Bold
        updatedAtLabel.textColor = .labelText
        view.addSubview(updatedAtLabel)
        NSLayoutConstraint.activate([
            updatedAtLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            updatedAtLabel.topAnchor.constraint(equalTo: view.topAnchor),
            updatedAtLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
            view.bottomAnchor.constraint(equalTo: updatedAtLabel.bottomAnchor)
        ])
        self.updatedAtLabel = updatedAtLabel
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
            if traitCollection.horizontalSizeClass == .regular,
               let layout = (view as? UICollectionView)?.collectionViewLayout as? UICollectionViewFlowLayout {
                attributes.frame.size.width = floor((attributes.frame.size.width - layout.minimumInteritemSpacing) / 2)
            }
        }
        return attributes
    }

    func configure(report: Report?, index: Int) {
        guard let report = report else { return }

        reportField.configure(from: report)
        responderField.configure(from: report)
        facilityField.configure(from: report.disposition?.destinationFacility)
        updatedAtLabel.text = report.updatedAt?.asRelativeString()
    }
}
