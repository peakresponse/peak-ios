//
//  SceneOverviewHeaderCell.swift
//  Triage
//
//  Created by Francis Li on 5/4/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit
import PRKit

class SceneOverviewHeaderCell: UICollectionViewCell {
    @IBOutlet weak var incidentNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var closeButton: PRKit.Button!
    @IBOutlet weak var editButton: PRKit.Button!
    @IBOutlet weak var hr: UIView!

    var calculatedSize: CGSize?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let incidentNumberLabel = UILabel()
        incidentNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        incidentNumberLabel.font = .h2Bold
        incidentNumberLabel.textColor = .text
        contentView.addSubview(incidentNumberLabel)
        NSLayoutConstraint.activate([
            incidentNumberLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            incidentNumberLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20)
        ])
        self.incidentNumberLabel = incidentNumberLabel

        let addressLabel = UILabel()
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = .h4SemiBold
        addressLabel.textColor = .labelText
        contentView.addSubview(addressLabel)
        NSLayoutConstraint.activate([
            addressLabel.topAnchor.constraint(equalTo: incidentNumberLabel.bottomAnchor),
            addressLabel.leftAnchor.constraint(equalTo: incidentNumberLabel.leftAnchor)
        ])
        self.addressLabel = addressLabel

        let timestampLabel = UILabel()
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.font = .body14Bold
        timestampLabel.textColor = .labelText
        contentView.addSubview(timestampLabel)
        NSLayoutConstraint.activate([
            timestampLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor),
            timestampLabel.leftAnchor.constraint(equalTo: addressLabel.leftAnchor),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: timestampLabel.bottomAnchor, constant: 10)
        ])
        self.timestampLabel = timestampLabel

        let closeButton = PRKit.Button()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.style = .destructive
        closeButton.size = .small
        contentView.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            closeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            incidentNumberLabel.rightAnchor.constraint(lessThanOrEqualTo: closeButton.leftAnchor, constant: -10),
            addressLabel.rightAnchor.constraint(lessThanOrEqualTo: closeButton.leftAnchor, constant: -10),
            timestampLabel.rightAnchor.constraint(lessThanOrEqualTo: closeButton.leftAnchor, constant: -10)
        ])
        self.closeButton = closeButton

        let editButton = PRKit.Button()
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.style = .secondary
        editButton.size = .small
        editButton.setTitle("Button.editScene".localized, for: .normal)
        contentView.addSubview(editButton)
        NSLayoutConstraint.activate([
            editButton.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 10),
            editButton.leftAnchor.constraint(equalTo: closeButton.leftAnchor),
            editButton.rightAnchor.constraint(equalTo: closeButton.rightAnchor),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: editButton.bottomAnchor, constant: 10)
        ])
        self.editButton = editButton

        let hr = UIView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.backgroundColor = .disabledBorder
        hr.heightAnchor.constraint(equalToConstant: 2).isActive = true
        contentView.addSubview(hr)
        NSLayoutConstraint.activate([
            hr.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            hr.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            hr.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        self.hr = hr
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        calculatedSize = nil
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if calculatedSize == nil {
            if traitCollection.horizontalSizeClass == .regular {
                calculatedSize = CGSize(width: 372, height: 136)
            } else {
                calculatedSize = CGSize(width: superview?.frame.width ?? 375, height: 136)
            }
        }
        layoutAttributes.size = calculatedSize ?? .zero
        return layoutAttributes
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
