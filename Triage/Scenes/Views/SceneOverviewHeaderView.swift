//
//  SceneOverviewHeaderCell.swift
//  Triage
//
//  Created by Francis Li on 5/4/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit
import PRKit

class SceneOverviewHeaderView: UIView {
    weak var containerView: UIView!
    weak var incidentNumberLabel: UILabel!
    weak var addressLabel: UILabel!
    weak var timestampLabel: UILabel!
    weak var closeButton: PRKit.Button!
    weak var editButton: PRKit.Button!
    weak var hr: UIView!

    var calculatedSize: CGSize?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .background

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        let containerViewLeftConstraint = containerView.leftAnchor.constraint(equalTo: leftAnchor)
        containerViewLeftConstraint.priority = .defaultHigh
        let containerViewRightConstraint = containerView.rightAnchor.constraint(equalTo: rightAnchor)
        containerViewRightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerViewLeftConstraint,
            containerViewRightConstraint,
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        self.containerView = containerView

        let incidentNumberLabel = UILabel()
        incidentNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        incidentNumberLabel.font = .h2Bold
        incidentNumberLabel.textColor = .text
        containerView.addSubview(incidentNumberLabel)
        NSLayoutConstraint.activate([
            incidentNumberLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            incidentNumberLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor)
        ])
        self.incidentNumberLabel = incidentNumberLabel

        let addressLabel = UILabel()
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = .h4SemiBold
        addressLabel.textColor = .labelText
        containerView.addSubview(addressLabel)
        NSLayoutConstraint.activate([
            addressLabel.topAnchor.constraint(equalTo: incidentNumberLabel.bottomAnchor),
            addressLabel.leftAnchor.constraint(equalTo: incidentNumberLabel.leftAnchor)
        ])
        self.addressLabel = addressLabel

        let timestampLabel = UILabel()
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.font = .body14Bold
        timestampLabel.textColor = .labelText
        containerView.addSubview(timestampLabel)
        NSLayoutConstraint.activate([
            timestampLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor),
            timestampLabel.leftAnchor.constraint(equalTo: addressLabel.leftAnchor),
            containerView.bottomAnchor.constraint(greaterThanOrEqualTo: timestampLabel.bottomAnchor, constant: 8)
        ])
        self.timestampLabel = timestampLabel

        let closeButton = PRKit.Button()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.style = .destructive
        closeButton.size = .small
        containerView.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            closeButton.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            incidentNumberLabel.rightAnchor.constraint(lessThanOrEqualTo: closeButton.leftAnchor, constant: -8),
            addressLabel.rightAnchor.constraint(lessThanOrEqualTo: closeButton.leftAnchor, constant: -8),
            timestampLabel.rightAnchor.constraint(lessThanOrEqualTo: closeButton.leftAnchor, constant: -8)
        ])
        self.closeButton = closeButton

        let editButton = PRKit.Button()
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.style = .secondary
        editButton.size = .small
        editButton.setTitle("Button.editScene".localized, for: .normal)
        containerView.addSubview(editButton)
        NSLayoutConstraint.activate([
            editButton.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            editButton.leftAnchor.constraint(equalTo: closeButton.leftAnchor),
            editButton.rightAnchor.constraint(equalTo: closeButton.rightAnchor),
            containerView.bottomAnchor.constraint(greaterThanOrEqualTo: editButton.bottomAnchor, constant: 18)
        ])
        self.editButton = editButton

        let hr = UIView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.backgroundColor = .disabledBorder
        hr.heightAnchor.constraint(equalToConstant: 2).isActive = true
        addSubview(hr)
        NSLayoutConstraint.activate([
            hr.leftAnchor.constraint(equalTo: leftAnchor),
            hr.rightAnchor.constraint(equalTo: rightAnchor),
            hr.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.hr = hr

        let heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = .defaultLow
        heightConstraint.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(from scene: Scene) {
        if let incident = scene.incident.first {
            incidentNumberLabel.text = "#\(incident.number ?? "")"
        }
        addressLabel.text = scene.address
        timestampLabel.text = scene.createdAt?.asDateTimeString()
        if scene.isMgs(userId: AppSettings.userId) {
            closeButton.setTitle("Button.closeScene".localized, for: .normal)
            editButton.isHidden = false
        } else if scene.isResponder(userId: AppSettings.userId) {
            closeButton.setTitle("Button.leaveScene".localized, for: .normal)
            editButton.isHidden = false
        } else {
            closeButton.setTitle("Button.exitScene".localized, for: .normal)
            editButton.isHidden = true
        }
    }
}
