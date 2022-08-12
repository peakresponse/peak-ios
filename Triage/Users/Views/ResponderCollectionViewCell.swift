//
//  ResponderCollectionViewCell.swift
//  Triage
//
//  Created by Francis Li on 5/29/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit

class ResponderCollectionViewCell: UICollectionViewCell {
    weak var unitLabel: UILabel!
    weak var agencyLabel: UILabel!
    weak var roleSelector: ResponderRoleSelector!
    weak var vr: UIView!

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
        let unitLabel = UILabel()
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.font = .h3SemiBold
        unitLabel.textColor = .base800
        contentView.addSubview(unitLabel)
        NSLayoutConstraint.activate([
            unitLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            unitLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20)
        ])
        self.unitLabel = unitLabel

        let agencyLabel = UILabel()
        agencyLabel.translatesAutoresizingMaskIntoConstraints = false
        agencyLabel.font = .body14Bold
        agencyLabel.textColor = .base800
        contentView.addSubview(agencyLabel)
        NSLayoutConstraint.activate([
            agencyLabel.firstBaselineAnchor.constraint(equalTo: unitLabel.firstBaselineAnchor),
            agencyLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            agencyLabel.leftAnchor.constraint(greaterThanOrEqualTo: unitLabel.rightAnchor)
        ])
        self.agencyLabel = agencyLabel

        let roleSelector = ResponderRoleSelector()
        roleSelector.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(roleSelector)
        NSLayoutConstraint.activate([
            roleSelector.topAnchor.constraint(equalTo: unitLabel.bottomAnchor, constant: 16),
            roleSelector.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            roleSelector.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: roleSelector.bottomAnchor, constant: 20)
        ])
        self.roleSelector = roleSelector

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
        guard let responder = responder else { return }
        var name = responder.user?.fullName
        if let vehicle = responder.vehicle {
            name = "\(vehicle.number ?? ""): \(name ?? "")"
        }
        unitLabel.text = name
        agencyLabel.text = responder.agency?.name
        roleSelector.source = responder
        roleSelector.attributeValue = responder.role as? NSObject
        vr.isHidden = traitCollection.horizontalSizeClass == .compact || !index.isMultiple(of: 2)
    }
}