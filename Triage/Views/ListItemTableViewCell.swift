//
//  ListItemTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 9/15/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

class ListItemTableViewCell: UITableViewCell {
    weak var label: UILabel!
    weak var disclosureImageView: UIImageView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        backgroundColor = .background
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = backgroundColor?.colorWithBrightnessMultiplier(multiplier: 0.8)

        let disclosureImageView = UIImageView(image: UIImage(named: "ChevronRight40px", in: PRKitBundle.instance, compatibleWith: nil))
        disclosureImageView.translatesAutoresizingMaskIntoConstraints = false
        disclosureImageView.image = UIImage(named: "ChevronRight40px", in: PRKitBundle.instance, compatibleWith: nil)
        disclosureImageView.tintColor = .labelText
        disclosureImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(disclosureImageView)
        NSLayoutConstraint.activate([
            disclosureImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            disclosureImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])
        self.disclosureImageView = disclosureImageView

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .h4SemiBold
        label.textColor = .text
        label.numberOfLines = 0
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            label.rightAnchor.constraint(equalTo: disclosureImageView.leftAnchor, constant: -10),
            contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 10)
        ])
        self.label = label
    }
}
