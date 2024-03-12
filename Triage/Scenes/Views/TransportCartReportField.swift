//
//  TransportCartReportField.swift
//  Triage
//
//  Created by Francis Li on 3/8/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

class TransportCartReportField: CellField {
    weak var priorityChip: Chip!
    weak var descLabel: UILabel!

    weak var report: Report?

    override func commonInit() {
        super.commonInit()
        isLabelHidden = true
        disclosureIndicatorView.image = UIImage(named: "Exit24px", in: PRKitBundle.instance, compatibleWith: nil)

        let priorityChip = Chip()
        priorityChip.size = .small
        priorityChip.translatesAutoresizingMaskIntoConstraints = false
        priorityChip.isUserInteractionEnabled = false
        contentView.addSubview(priorityChip)
        NSLayoutConstraint.activate([
            priorityChip.rightAnchor.constraint(equalTo: disclosureIndicatorView.leftAnchor, constant: -6),
            priorityChip.centerYAnchor.constraint(equalTo: disclosureIndicatorView.centerYAnchor)
        ])
        self.priorityChip = priorityChip

        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .body14Bold
        descLabel.textColor = .base500
        contentView.addSubview(descLabel)
        NSLayoutConstraint.activate([
            descLabel.centerYAnchor.constraint(equalTo: priorityChip.centerYAnchor),
            descLabel.leftAnchor.constraint(equalTo: textLabel.rightAnchor, constant: 8),
            descLabel.rightAnchor.constraint(equalTo: priorityChip.leftAnchor, constant: -6)
        ])
        self.descLabel = descLabel

        for constraint in contentView.constraints {
            if (constraint.firstItem as? UILabel) == textLabel && (constraint.secondItem as? UIImageView) == disclosureIndicatorView {
                constraint.isActive = false
                break
            }
        }

        textLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        priorityChip.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        disclosureIndicatorView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    func configure(from report: Report?) {
        self.report = report
        text = "#\(report?.pin ?? "")"
        descLabel.text = report?.description

        let priority = TriagePriority(rawValue: report?.patient?.priority ?? -1) ?? .unknown
        priorityChip.color = priority.color
        priorityChip.setTitle(priority.description, for: .normal)
    }
}
