//
//  ResponderTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/7/26.
//  Copyright © 2026 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

@objc protocol ResponderTableViewCellDelegate {
    @objc optional func responderTableViewCell(_ cell: ResponderTableViewCell, didToggle isSelected: Bool)
    @objc optional func responderTableViewCellDidMarkArrived(_ cell: ResponderTableViewCell, responderId: String?)
}

class ResponderTableViewCell: UITableViewCell, CheckboxDelegate {
    var responderId: String?
    var isSelectable = false

    weak var containerView: UIStackView!
    weak var checkbox: Checkbox!
    weak var unitLabel: UILabel!
    weak var agencyLabel: UILabel!
    weak var timestampLabel: UILabel!
    weak var chip: Chip!
    weak var button: PRKit.Button!

    var containerViewConstraints: [NSLayoutConstraint] = []
    var chipZeroWidthConstraint: NSLayoutConstraint!

    weak var delegate: ResponderTableViewCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        backgroundColor = .background

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .highlight
        self.selectedBackgroundView = selectedBackgroundView

        let containerView = UIStackView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.axis = .horizontal
        containerView.spacing = 20
        containerView.alignment = .center
        contentView.addSubview(containerView)
        let containerViewLeftConstraint = containerView.leftAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leftAnchor, constant: 16)
        containerViewLeftConstraint.priority = .defaultHigh
        let containerViewRightConstraint = containerView.rightAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.rightAnchor, constant: -16)
        containerViewRightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 16),
            containerViewLeftConstraint,
            containerViewRightConstraint,
            containerView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -18)
        ])
        self.containerView = containerView

        let checkbox = Checkbox()
        checkbox.delegate = self
        checkbox.isHidden = !isSelectable
        checkbox.isRadioButton = true
        checkbox.isRadioButtonDeselectable = true
        checkbox.label.superview?.isHidden = true
        checkbox.heightAnchor.constraint(equalToConstant: 40).isActive = true
        checkbox.widthAnchor.constraint(equalToConstant: 40).isActive = true
        containerView.addArrangedSubview(checkbox)
        self.checkbox = checkbox

        let col = UIStackView()
        col.axis = .vertical
        col.spacing = 4
        col.alignment = .fill
        containerView.addArrangedSubview(col)

        let view = UIView()
        col.addArrangedSubview(view)

        let chip = Chip()
        chip.translatesAutoresizingMaskIntoConstraints = false
        chip.color = .brandPrimary500
        chip.tintColor = .white
        chip.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        chip.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        chip.alpha = 0
        view.addSubview(chip)
        chipZeroWidthConstraint = chip.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            chip.topAnchor.constraint(equalTo: view.topAnchor),
            chip.rightAnchor.constraint(equalTo: view.rightAnchor),
            chipZeroWidthConstraint,
            view.bottomAnchor.constraint(equalTo: chip.bottomAnchor)
        ])
        self.chip = chip

        let unitLabel = UILabel()
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.font = .h3SemiBold
        unitLabel.textColor = .text
        unitLabel.numberOfLines = 1
        unitLabel.lineBreakMode = .byTruncatingTail
        unitLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.addSubview(unitLabel)
        NSLayoutConstraint.activate([
            unitLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
            unitLabel.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
            unitLabel.rightAnchor.constraint(equalTo: chip.leftAnchor, constant: -8)
        ])
        self.unitLabel = unitLabel

        let agencyLabel = UILabel()
        agencyLabel.font = .h4
        agencyLabel.textColor = .labelText
        col.addArrangedSubview(agencyLabel)
        self.agencyLabel = agencyLabel

        let timestampLabel = UILabel()
        timestampLabel.font = .body14Bold
        timestampLabel.textColor = .labelText
        col.addArrangedSubview(timestampLabel)
        self.timestampLabel = timestampLabel

        let button = PRKit.Button()
        button.style = .primary
        button.size = .small
        button.setTitle("Button.markArrived".localized, for: .normal)
        button.addTarget(self, action: #selector(markArrivedPressed(_:)), for: .touchUpInside)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        containerView.addArrangedSubview(button)
        self.button = button

        let hr = UIView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.backgroundColor = .disabledBorder
        contentView.addSubview(hr)
        NSLayoutConstraint.activate([
            hr.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            hr.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            hr.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hr.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    func constrain(to view: UIView) {
        NSLayoutConstraint.deactivate(containerViewConstraints)
        containerViewConstraints.removeAll()
        containerViewConstraints.append(contentsOf: [
            containerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        NSLayoutConstraint.activate(containerViewConstraints)
    }

    func configure(from responder: Responder?, isSelected: Bool = false) {
        responderId = responder?.id
        checkbox.isChecked = isSelected

        guard let responder = responder else { return }
        unitLabel.text = "\(responder.vehicle?.identifier ?? responder.identifier ?? "")"
        if let user = responder.user {
            unitLabel.text = "\(unitLabel.text ?? ""): \(user.fullNameLastFirst)"
        }
        agencyLabel.text = responder.agency?.displayName
        if let arrivedAt = responder.arrivedAt {
            checkbox.isHidden = !isSelectable
            timestampLabel.text = arrivedAt.asRelativeString()
            button.isHidden = true
        } else {
            checkbox.isHidden = true
            timestampLabel.text = "Responder.status.enroute".localized
            button.isHidden = false
        }
        if let role = responder.sceneRole {
            chip.alpha = 1
            chipZeroWidthConstraint.isActive = false
            chip.setTitle("Responder.role.short.\(role)".localized, for: .normal)
            chip.setTitleColor(.white, for: .normal)
            chip.color = .base500
        } else if let capability = responder.capability {
            chip.alpha = 1
            chipZeroWidthConstraint.isActive = false
            chip.setTitle("Responder.capability.\(capability)".localized, for: .normal)
            if capability == ResponseUnitTransportAndEquipmentCapability.groundTransportAls.rawValue {
                chip.setTitleColor(.white, for: .normal)
                chip.color = .triageMinimalMedium
            } else {
                chip.setTitleColor(.white, for: .normal)
                chip.color = .triageDelayedMedium
            }
        } else {
            chip.alpha = 0
            chipZeroWidthConstraint.isActive = true
        }
    }

    @objc func markArrivedPressed(_ sender: RoundButton) {
        delegate?.responderTableViewCellDidMarkArrived?(self, responderId: responderId)
    }

    // MARK: - CheckboxDelegate

    func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        delegate?.responderTableViewCell?(self, didToggle: isChecked)
    }
}
