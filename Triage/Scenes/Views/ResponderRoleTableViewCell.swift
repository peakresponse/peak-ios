//
//  ResponderRoleTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/11/26.
//  Copyright © 2026 Francis Li. All rights reserved.
//

import PRKit
import UIKit

class ResponderRoleTableViewCell: UITableViewCell {
    var responderId: String?
    weak var containerView: UIView!
    weak var unitLabel: UILabel!
    weak var roleSelector: PRKit.TextField!

    var containerViewConstraints: [NSLayoutConstraint] = []
    var containerContentConstraints: [NSLayoutConstraint] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commonInit() {
        backgroundColor = .background

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        let containerViewLeftConstraint = containerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
        containerViewLeftConstraint.priority = .defaultHigh
        let containerViewRightConstraint = containerView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16)
        containerViewRightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            containerViewLeftConstraint,
            containerViewRightConstraint,
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 18)
        ])
        self.containerView = containerView

        let unitLabel = UILabel()
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.font = .h3SemiBold
        unitLabel.textColor = .text
        containerView.addSubview(unitLabel)
        self.unitLabel = unitLabel

        let roleSelector = PRKit.TextField()
        roleSelector.translatesAutoresizingMaskIntoConstraints = false
        roleSelector.attributeType = .single(EnumKeyboardSource<ResponderRole>())
        roleSelector.placeholderText = "Responder.role.assign".localized
        roleSelector.isLabelHidden = true
        roleSelector.clearButton.alpha = 0
        containerView.addSubview(roleSelector)
        self.roleSelector = roleSelector

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

        updateLayout()
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

    func updateLayout() {
        NSLayoutConstraint.deactivate(containerContentConstraints)
        containerContentConstraints.removeAll()
        if traitCollection.horizontalSizeClass == .regular {
            containerContentConstraints.append(contentsOf: [
                unitLabel.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor),
                unitLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor),
                unitLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5, constant: -8),
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: unitLabel.bottomAnchor),
                roleSelector.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor),
                roleSelector.rightAnchor.constraint(equalTo: containerView.rightAnchor),
                roleSelector.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5, constant: -8),
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: roleSelector.bottomAnchor),
                unitLabel.centerYAnchor.constraint(equalTo: roleSelector.centerYAnchor)
            ])
        } else {
            containerContentConstraints.append(contentsOf: [
                unitLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
                unitLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor),
                unitLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor),
                roleSelector.topAnchor.constraint(equalTo: unitLabel.bottomAnchor, constant: 8),
                roleSelector.leftAnchor.constraint(equalTo: containerView.leftAnchor),
                roleSelector.rightAnchor.constraint(equalTo: containerView.rightAnchor),
                containerView.bottomAnchor.constraint(equalTo: roleSelector.bottomAnchor)
            ])
        }
        NSLayoutConstraint.activate(containerContentConstraints)
    }

    func configure(from responder: Responder?) {
        responderId = responder?.id

        guard let responder = responder else { return }
        var name = responder.user?.fullNameLastFirst
        if let vehicle = responder.vehicle {
            name = "\(vehicle.number ?? ""): \(name ?? "")"
        }
        unitLabel.text = name
        roleSelector.source = responder
        roleSelector.attributeValue = responder.sceneRole as? NSObject
        let role = ResponderRole(rawValue: responder.sceneRole ?? "")
        if role?.isLeader ?? false {
            roleSelector.clearButton.alpha = 0
        } else {
            roleSelector.clearButton.alpha = 1
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            updateLayout()
        }
    }
}
