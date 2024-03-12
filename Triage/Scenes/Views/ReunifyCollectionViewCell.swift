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
    weak var vr: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .base100
        self.selectedBackgroundView = selectedBackgroundView

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
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
        updatedAtLabel.textColor = .base500
        view.addSubview(updatedAtLabel)
        NSLayoutConstraint.activate([
            updatedAtLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            updatedAtLabel.topAnchor.constraint(equalTo: view.topAnchor),
            updatedAtLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
            view.bottomAnchor.constraint(equalTo: updatedAtLabel.bottomAnchor)
        ])
        self.updatedAtLabel = updatedAtLabel

        let hr = UIView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.backgroundColor = .base300
        contentView.addSubview(hr)
        NSLayoutConstraint.activate([
            hr.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            hr.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            hr.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hr.heightAnchor.constraint(equalToConstant: 2)
        ])

        let vr = UIView()
        vr.translatesAutoresizingMaskIntoConstraints = false
        vr.backgroundColor = .base300
        contentView.addSubview(vr)
        NSLayoutConstraint.activate([
            vr.topAnchor.constraint(equalTo: contentView.topAnchor),
            vr.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            vr.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            vr.widthAnchor.constraint(equalToConstant: 2)
        ])
        self.vr = vr
    }

    func configure(report: Report?, index: Int) {
        guard let report = report else { return }

        reportField.configure(from: report)
        responderField.configure(from: report)
        facilityField.configure(from: report.disposition?.destinationFacility)
        updatedAtLabel.text = report.updatedAt?.asRelativeString()

        vr.isHidden = traitCollection.horizontalSizeClass == .compact || !index.isMultiple(of: 2)
    }
}
