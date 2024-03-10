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
    weak var timestampLabel: UILabel!
    weak var chip: Chip!
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
        let row = UIStackView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.spacing = 20
        row.alignment = .center
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            row.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        let col = UIStackView()
        col.axis = .vertical
        col.spacing = 4
        col.alignment = .fill
        row.addArrangedSubview(col)

        let view = UIView()
        col.addArrangedSubview(view)

        let chip = Chip()
        chip.translatesAutoresizingMaskIntoConstraints = false
        chip.color = .brandPrimary500
        chip.tintColor = .white
        chip.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.addSubview(chip)
        NSLayoutConstraint.activate([
            chip.topAnchor.constraint(equalTo: view.topAnchor),
            chip.rightAnchor.constraint(equalTo: view.rightAnchor),
            view.bottomAnchor.constraint(equalTo: chip.bottomAnchor)
        ])
        self.chip = chip

        let unitLabel = UILabel()
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.font = .h3SemiBold
        unitLabel.textColor = .base800
        unitLabel.numberOfLines = 1
        unitLabel.lineBreakMode = .byTruncatingTail
        view.addSubview(unitLabel)
        NSLayoutConstraint.activate([
            unitLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
            unitLabel.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
            unitLabel.rightAnchor.constraint(equalTo: chip.leftAnchor, constant: -8)
        ])
        self.unitLabel = unitLabel

        let agencyLabel = UILabel()
        agencyLabel.font = .h4
        agencyLabel.textColor = .base500
        col.addArrangedSubview(agencyLabel)
        self.agencyLabel = agencyLabel

        let timestampLabel = UILabel()
        timestampLabel.font = .body14Bold
        timestampLabel.textColor = .base500
        col.addArrangedSubview(timestampLabel)
        self.timestampLabel = timestampLabel

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
                calculatedSize = CGSize(width: 372, height: 125)
            } else {
                calculatedSize = CGSize(width: superview?.frame.width ?? 375, height: 125)
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
            timestampLabel.text = arrivedAt.asRelativeString()
            button.isHidden = true
        } else {
            timestampLabel.text = "Responder.status.enroute".localized
            button.isHidden = false
        }
        if let capability = responder.capability {
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
            chip.alpha = 0
        }
        vr.isHidden = traitCollection.horizontalSizeClass == .compact || !index.isMultiple(of: 2)
    }

    @objc func markArrivedPressed(_ sender: RoundButton) {
        delegate?.responderCollectionViewCellDidMarkArrived?(self, responderId: responderId)
    }
}
