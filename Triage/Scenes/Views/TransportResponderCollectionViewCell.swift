//
//  TransportResponderCollectionViewCell.swift
//  Triage
//
//  Created by Francis Li on 3/7/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

class TransportResponderCollectionViewCell: UICollectionViewCell {
    weak var checkbox: Checkbox!
    weak var unitLabel: UILabel!
    weak var agencyLabel: UILabel!
    weak var updatedAtLabel: UILabel!
    weak var capabilityChip: Chip!
    weak var button: PRKit.Button!

    var calculatedSize: CGSize?

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

        let checkbox = Checkbox()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.isUserInteractionEnabled = false
        checkbox.isRadioButton = true
        checkbox.isRadioButtonDeselectable = true
        checkbox.label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            checkbox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        self.checkbox = checkbox

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .fill
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leftAnchor.constraint(equalTo: checkbox.rightAnchor, constant: 12),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(view)

        let capabilityChip = Chip()
        capabilityChip.translatesAutoresizingMaskIntoConstraints = false
        capabilityChip.color = .brandPrimary500
        capabilityChip.tintColor = .white
        capabilityChip.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        capabilityChip.alpha = 0
        view.addSubview(capabilityChip)
        NSLayoutConstraint.activate([
            capabilityChip.topAnchor.constraint(equalTo: view.topAnchor),
            capabilityChip.rightAnchor.constraint(equalTo: view.rightAnchor),
            view.bottomAnchor.constraint(equalTo: capabilityChip.bottomAnchor)
        ])
        self.capabilityChip = capabilityChip

        let unitLabel = UILabel()
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.font = .h3SemiBold
        unitLabel.textColor = .base800
        unitLabel.numberOfLines = 1
        unitLabel.lineBreakMode = .byTruncatingTail
        view.addSubview(unitLabel)
        NSLayoutConstraint.activate([
            unitLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
            unitLabel.centerYAnchor.constraint(equalTo: capabilityChip.centerYAnchor),
            unitLabel.rightAnchor.constraint(equalTo: capabilityChip.leftAnchor, constant: -10)
        ])
        self.unitLabel = unitLabel

        let agencyLabel = UILabel()
        agencyLabel.translatesAutoresizingMaskIntoConstraints = false
        agencyLabel.font = .h4
        agencyLabel.textColor = .base500
        stackView.addArrangedSubview(agencyLabel)
        self.agencyLabel = agencyLabel

        let updatedAtLabel = UILabel()
        updatedAtLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedAtLabel.font = .body14Bold
        updatedAtLabel.textColor = .base500
        stackView.addArrangedSubview(updatedAtLabel)
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

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        calculatedSize = nil
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if calculatedSize == nil {
            if traitCollection.horizontalSizeClass == .regular {
                calculatedSize = CGSize(width: 372, height: 125)
            } else {
                calculatedSize = CGSize(width: superview?.frame.width ?? 375, height: 125)
            }
        }
        layoutAttributes.size = calculatedSize ?? .zero
        return layoutAttributes
    }

    func configure(from responder: Responder?, index: Int, isSelected: Bool) {
        guard let responder = responder else { return }
        checkbox.isChecked = isSelected
        unitLabel.text = responder.vehicle?.callSign ?? responder.vehicle?.number ?? responder.unitNumber
        agencyLabel.text = responder.agency?.name
        if let capability = responder.capability {
            capabilityChip.alpha = 1
            capabilityChip.setTitle("Responder.capability.\(capability)".localized, for: .normal)
            if capability == ResponseUnitTransportAndEquipmentCapability.groundTransportAls.rawValue {
                capabilityChip.setTitleColor(.white, for: .normal)
                capabilityChip.color = .brandPrimary500
            } else {
                capabilityChip.setTitleColor(.base800, for: .normal)
                capabilityChip.color = .triageDelayedMedium
            }
        } else {
            capabilityChip.alpha = 0
        }
        updatedAtLabel.text = responder.arrivedAt?.asRelativeString()
    }
}
