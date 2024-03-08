//
//  ResponderCollectionViewCell.swift
//  Triage
//
//  Created by Francis Li on 2/23/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

@objc protocol ResponderCollectionViewCellDelegate {
    @objc optional func responderCollectionViewCellDidMarkArrived(_ cell: ResponderCollectionViewCell, responderId: String?)
}

class ResponderCollectionViewCell: UICollectionViewCell {
    var responderId: String?
    weak var unitLabel: UILabel!
    weak var agencyLabel: UILabel!
    weak var timestampChip: Chip!
    weak var button: PRKit.Button!
    weak var vr: UIView!

    weak var delegate: ResponderCollectionViewCellDelegate?

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
        let timestampChip = Chip()
        timestampChip.translatesAutoresizingMaskIntoConstraints = false
        timestampChip.size = .small
        timestampChip.color = .brandPrimary500
        timestampChip.tintColor = .white
        timestampChip.bundleImage = "Clock24px"
        timestampChip.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(timestampChip)
        NSLayoutConstraint.activate([
            timestampChip.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            timestampChip.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)
        ])
        self.timestampChip = timestampChip

        let unitLabel = UILabel()
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.font = .h3SemiBold
        unitLabel.textColor = .base800
        unitLabel.numberOfLines = 1
        unitLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(unitLabel)
        NSLayoutConstraint.activate([
            unitLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            unitLabel.centerYAnchor.constraint(equalTo: timestampChip.centerYAnchor),
            unitLabel.rightAnchor.constraint(equalTo: timestampChip.leftAnchor, constant: -20)
        ])
        self.unitLabel = unitLabel

        let agencyLabel = UILabel()
        agencyLabel.translatesAutoresizingMaskIntoConstraints = false
        agencyLabel.font = .h4
        agencyLabel.textColor = .base800
        contentView.addSubview(agencyLabel)
        NSLayoutConstraint.activate([
            agencyLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            agencyLabel.topAnchor.constraint(equalTo: unitLabel.bottomAnchor, constant: 4),
            agencyLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)
        ])
        self.agencyLabel = agencyLabel

        let button = PRKit.Button()
        button.style = .primary
        button.size = .small
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Button.markArrived".localized, for: .normal)
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: agencyLabel.bottomAnchor, constant: 4),
            button.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)
        ])
        button.addTarget(self, action: #selector(markArrivedPressed(_:)), for: .touchUpInside)
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

    func configure(from responder: Responder?, index: Int, isMGS: Bool) {
        responderId = responder?.id
        guard let responder = responder else { return }
        unitLabel.text = "\("Responder.unitNumber".localized)\(responder.vehicle?.callSign ?? responder.vehicle?.number ?? responder.unitNumber ?? "")"
        agencyLabel.text = responder.agency?.name
        if let arrivedAt = responder.arrivedAt {
            timestampChip.color = .brandPrimary500
            timestampChip.setTitle(String(format: "ResponderCollectionViewCell.arrivedAt".localized, arrivedAt.asRelativeString()), for: .normal)
            button.isHidden = true
        } else {
            timestampChip.color = .base500
            timestampChip.setTitle("Responder.status.enroute".localized, for: .normal)
            button.isHidden = false
        }
        vr.isHidden = traitCollection.horizontalSizeClass == .compact || !index.isMultiple(of: 2)
    }

    @objc func markArrivedPressed(_ sender: RoundButton) {
        delegate?.responderCollectionViewCellDidMarkArrived?(self, responderId: responderId)
    }
}
