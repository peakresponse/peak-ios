//
//  TransportCartResponderField.swift
//  Triage
//
//  Created by Francis Li on 3/8/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

class TransportCartResponderField: CellField {
    weak var chip: Chip!
    var chipWidthConstraint: NSLayoutConstraint!
    weak var agencyLabel: UILabel!

    weak var responder: Responder?

    override func commonInit() {
        super.commonInit()
        isLabelHidden = true
        disclosureIndicatorView.image = UIImage(named: "Exit24px", in: PRKitBundle.instance, compatibleWith: nil)

        let chip = Chip()
        chip.size = .small
        chip.translatesAutoresizingMaskIntoConstraints = false
        chip.isUserInteractionEnabled = false
        contentView.addSubview(chip)
        NSLayoutConstraint.activate([
            chip.rightAnchor.constraint(equalTo: disclosureIndicatorView.leftAnchor, constant: -6),
            chip.centerYAnchor.constraint(equalTo: disclosureIndicatorView.centerYAnchor)
        ])
        self.chip = chip

        chipWidthConstraint = chip.widthAnchor.constraint(equalToConstant: 0)
        chipWidthConstraint.isActive = false

        let agencyLabel = UILabel()
        agencyLabel.translatesAutoresizingMaskIntoConstraints = false
        agencyLabel.font = .body14Bold
        agencyLabel.textColor = .labelText
        contentView.addSubview(agencyLabel)
        NSLayoutConstraint.activate([
            agencyLabel.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
            agencyLabel.leftAnchor.constraint(equalTo: textLabel.rightAnchor, constant: 8),
            agencyLabel.rightAnchor.constraint(equalTo: chip.leftAnchor, constant: -6)
        ])
        self.agencyLabel = agencyLabel

        for constraint in contentView.constraints {
            if (constraint.firstItem as? UILabel) == textLabel && (constraint.secondItem as? UIImageView) == disclosureIndicatorView {
                constraint.isActive = false
                break
            }
        }

        textLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        chip.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        disclosureIndicatorView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    func configure(from responder: Responder?) {
        self.responder = responder
        text = "\("Responder.unitNumber".localized)\(responder?.vehicle?.callSign ?? responder?.vehicle?.number ?? responder?.unitNumber ?? "")"
        agencyLabel.text = responder?.agency?.displayName

        if let capability = responder?.capability {
            chipWidthConstraint.isActive = false
            chip.alpha = 1
            chip.setTitle("Responder.capability.\(capability)".localized, for: .normal)
            if capability == ResponseUnitTransportAndEquipmentCapability.groundTransportAls.rawValue {
                chip.setTitleColor(.white, for: .normal)
                chip.color = .brandPrimary500
            } else {
                chip.setTitleColor(.base800, for: .normal)
                chip.color = .triageDelayedMedium
            }
        } else {
            chipWidthConstraint.isActive = true
            chip.alpha = 0
            chip.setTitle("", for: .normal)
        }
    }

    func configure(from report: Report?) {
        text = "\("Responder.unitNumber".localized)\(report?.response?.unitNumber ?? "")"
        agencyLabel.text = report?.response?.agency?.displayName

        chipWidthConstraint.isActive = true
        chip.alpha = 0
        chip.setTitle("", for: .normal)
    }
}
