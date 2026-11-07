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
        containerView.spacing = 16
        containerView.alignment = .center
        contentView.addSubview(containerView)
        let containerViewLeftConstraint = containerView.leftAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leftAnchor,
                                                                              constant: 16)
        containerViewLeftConstraint.priority = .defaultHigh
        let containerViewRightConstraint = containerView.rightAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.rightAnchor,
                                                                                constant: -16)
        containerViewRightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 16),
            containerViewLeftConstraint,
            containerViewRightConstraint,
            containerView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -18)
        ])
        self.containerView = containerView

        let checkbox = Checkbox()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.delegate = self
        checkbox.isHidden = !isSelectable
        checkbox.isRadioButton = true
        checkbox.isRadioButtonDeselectable = true
        checkbox.label.superview?.isHidden = true
        checkbox.heightAnchor.constraint(equalToConstant: 40).isActive = true
        checkbox.widthAnchor.constraint(equalToConstant: 40).isActive = true
        containerView.addArrangedSubview(checkbox)
        self.checkbox = checkbox

        let unitLabel = UILabel()
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.font = .h3SemiBold
        unitLabel.textColor = .text
        unitLabel.numberOfLines = 1
        unitLabel.lineBreakMode = .byTruncatingTail
        unitLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.unitLabel = unitLabel

        let agencyLabel = UILabel()
        agencyLabel.translatesAutoresizingMaskIntoConstraints = false
        agencyLabel.font = .h4
        agencyLabel.textColor = .labelText
        self.agencyLabel = agencyLabel

        let timestampLabel = UILabel()
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.font = .body14Bold
        timestampLabel.textColor = .labelText
        self.timestampLabel = timestampLabel

        let chip = Chip()
        chip.translatesAutoresizingMaskIntoConstraints = false
        chip.color = .brandPrimary500
        chip.tintColor = .white
        chip.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        chip.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        chip.isHidden = true
        self.chip = chip

        let button = PRKit.Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        button.size = .small
        button.setTitle("Button.markArrived".localized, for: .normal)
        button.addTarget(self, action: #selector(markArrivedPressed(_:)), for: .touchUpInside)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.button = button

        updateLayout()

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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateLayout()
        }
    }

    func updateLayout() {
        for view in containerView.arrangedSubviews {
            view.removeFromSuperview()
        }
        chip.removeFromSuperview()
        unitLabel.removeFromSuperview()
        agencyLabel.removeFromSuperview()
        timestampLabel.removeFromSuperview()
        button.removeFromSuperview()

        containerView.addArrangedSubview(checkbox)

        if traitCollection.horizontalSizeClass == .regular {
            var view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            containerView.addArrangedSubview(view)

            view.addSubview(unitLabel)
            view.addSubview(agencyLabel)
            view.addSubview(timestampLabel)
            NSLayoutConstraint.activate([
                unitLabel.topAnchor.constraint(equalTo: view.topAnchor),
                unitLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
                view.bottomAnchor.constraint(equalTo: unitLabel.bottomAnchor),
                agencyLabel.leftAnchor.constraint(equalTo: unitLabel.rightAnchor, constant: 16),
                agencyLabel.centerYAnchor.constraint(equalTo: unitLabel.centerYAnchor),
                timestampLabel.leftAnchor.constraint(greaterThanOrEqualTo: agencyLabel.rightAnchor, constant: 16),
                timestampLabel.centerYAnchor.constraint(equalTo: agencyLabel.centerYAnchor),
                timestampLabel.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])

            view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            containerView.addArrangedSubview(view)

            let row = UIStackView()
            row.translatesAutoresizingMaskIntoConstraints = false
            row.axis = .horizontal
            row.spacing = 8
            view.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: view.topAnchor),
                row.rightAnchor.constraint(equalTo: view.rightAnchor),
                row.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor),
                view.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                view.widthAnchor.constraint(greaterThanOrEqualTo: containerView.widthAnchor, multiplier: 0.33, constant: -8)
            ])

            row.addArrangedSubview(button)
            row.addArrangedSubview(chip)
        } else {
            var col = UIStackView()
            col.translatesAutoresizingMaskIntoConstraints = false
            col.axis = .vertical
            col.spacing = 4
            col.alignment = .fill
            containerView.addArrangedSubview(col)

            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.heightAnchor.constraint(equalToConstant: 36).isActive = true
            view.addSubview(unitLabel)
            NSLayoutConstraint.activate([
                unitLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
                unitLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                unitLabel.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
            col.addArrangedSubview(view)
            col.addArrangedSubview(agencyLabel)
            col.addArrangedSubview(timestampLabel)

            col = UIStackView()
            col.translatesAutoresizingMaskIntoConstraints = false
            col.axis = .vertical
            col.spacing = 8
            col.alignment = .fill
            containerView.addArrangedSubview(col)

            col.addArrangedSubview(chip)
            col.addArrangedSubview(button)
        }
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
            button.alpha = 0
        } else {
            checkbox.isHidden = true
            timestampLabel.text = "Responder.status.enroute".localized
            button.alpha = 1
        }
        if let role = responder.sceneRole {
            chip.isHidden = false
            chip.setTitle("Responder.role.short.\(role)".localized, for: .normal)
            chip.setTitleColor(.white, for: .normal)
            chip.color = .base500
        } else if let capability = responder.capability {
            chip.isHidden = false
            chip.setTitle("Responder.capability.\(capability)".localized, for: .normal)
            if capability == ResponseUnitTransportAndEquipmentCapability.groundTransportAls.rawValue {
                chip.setTitleColor(.white, for: .normal)
                chip.color = .triageMinimalMedium
            } else {
                chip.setTitleColor(.white, for: .normal)
                chip.color = .triageDelayedMedium
            }
        } else {
            chip.isHidden = true
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
