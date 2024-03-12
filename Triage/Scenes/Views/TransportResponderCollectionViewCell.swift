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

@objc protocol TransportResponderCollectionViewCellDelegate {
    @objc optional func transportResponderCollectionViewCellDidPressMarkArrived(_ cell: TransportResponderCollectionViewCell)
}

class TransportResponderCollectionViewCell: UICollectionViewCell {
    var responderId: String?

    weak var checkbox: Checkbox!
    weak var unitLabel: UILabel!
    weak var agencyLabel: UILabel!
    weak var updatedAtLabel: UILabel!
    weak var capabilityChip: Chip!
    weak var button: PRKit.Button!

    weak var delegate: TransportResponderCollectionViewCellDelegate?

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

        let row = UIStackView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 20
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            row.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        let checkbox = Checkbox()
        checkbox.isUserInteractionEnabled = false
        checkbox.isRadioButton = true
        checkbox.isRadioButtonDeselectable = true
        checkbox.label.superview?.isHidden = true
        checkbox.widthAnchor.constraint(equalToConstant: 40).isActive = true
        row.addArrangedSubview(checkbox)
        self.checkbox = checkbox

        let col = UIStackView()
        col.axis = .vertical
        col.spacing = 4
        col.alignment = .fill
        row.addArrangedSubview(col)

        let view = UIView()
        col.addArrangedSubview(view)

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
        unitLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
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
        col.addArrangedSubview(agencyLabel)
        self.agencyLabel = agencyLabel

        let updatedAtLabel = UILabel()
        updatedAtLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedAtLabel.font = .body14Bold
        updatedAtLabel.textColor = .base500
        col.addArrangedSubview(updatedAtLabel)
        self.updatedAtLabel = updatedAtLabel

        let button = PRKit.Button()
        button.style = .primary
        button.size = .small
        button.setTitle("Button.markArrived".localized, for: .normal)
        button.addTarget(self, action: #selector(markArrivedPressed(_:)), for: .touchUpInside)
        row.addArrangedSubview(button)
        self.button = button

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
        responderId = responder?.id
        checkbox.isChecked = isSelected

        guard let responder = responder else { return }
        unitLabel.text = "\("Responder.unitNumber".localized)\(responder.vehicle?.callSign ?? responder.vehicle?.number ?? responder.unitNumber ?? "")"
        agencyLabel.text = responder.agency?.displayName
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
        if let arrivedAt = responder.arrivedAt {
            checkbox.isHidden = false
            updatedAtLabel.text = arrivedAt.asRelativeString()
            button.isHidden = true
        } else {
            checkbox.isHidden = true
            updatedAtLabel.text = "Responder.status.enroute".localized
            button.isHidden = false
        }
    }

    @objc func markArrivedPressed(_ sender: PRKit.Button) {
        delegate?.transportResponderCollectionViewCellDidPressMarkArrived?(self)
    }
}
