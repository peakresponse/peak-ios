//
//  TransportReportCollectionViewCell.swift
//  Triage
//
//  Created by Francis Li on 3/7/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

class TransportReportCollectionViewCell: UICollectionViewCell {
    weak var checkbox: Checkbox!
    weak var priorityChip: Chip!
    weak var originalPriorityChip: Chip!
    var originalPriorityChipWidthConstraint: NSLayoutConstraint!
    weak var tagLabel: UILabel!
    weak var descLabel: UILabel!
    var descLabelRightViewConstraint: NSLayoutConstraint!
    var descLabelRightPriorityChipConstraint: NSLayoutConstraint!
    weak var updatedAtLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .base100
        self.selectedBackgroundView = selectedBackgroundView

        let row = UIStackView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 20
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            row.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        let checkbox = Checkbox()
        checkbox.isUserInteractionEnabled = false
        checkbox.label.superview?.isHidden = true
        checkbox.widthAnchor.constraint(equalToConstant: 40).isActive = true
        row.addArrangedSubview(checkbox)
        self.checkbox = checkbox

        let col = UIStackView()
        col.axis = .vertical
        col.spacing = 4
        col.alignment = .fill
        row.addArrangedSubview(col)

        var view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        col.addArrangedSubview(view)

        let priorityChip = Chip()
        priorityChip.translatesAutoresizingMaskIntoConstraints = false
        priorityChip.isUserInteractionEnabled = false
        priorityChip.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.addSubview(priorityChip)
        NSLayoutConstraint.activate([
            priorityChip.topAnchor.constraint(equalTo: view.topAnchor),
            priorityChip.rightAnchor.constraint(equalTo: view.rightAnchor),
            view.bottomAnchor.constraint(equalTo: priorityChip.bottomAnchor)
        ])
        self.priorityChip = priorityChip

        let tagLabel = UILabel()
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.font = .h3SemiBold
        tagLabel.textColor = .base800
        view.addSubview(tagLabel)
        NSLayoutConstraint.activate([
            tagLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
            tagLabel.centerYAnchor.constraint(equalTo: priorityChip.centerYAnchor),
            tagLabel.rightAnchor.constraint(lessThanOrEqualTo: priorityChip.leftAnchor, constant: -10)
        ])
        self.tagLabel = tagLabel

        view = UIView()
        col.addArrangedSubview(view)

        let originalPriorityChip = Chip()
        originalPriorityChip.translatesAutoresizingMaskIntoConstraints = false
        originalPriorityChip.isUserInteractionEnabled = false
        originalPriorityChip.isHidden = true
        view.addSubview(originalPriorityChip)
        originalPriorityChipWidthConstraint = originalPriorityChip.widthAnchor.constraint(equalTo: priorityChip.widthAnchor)
        NSLayoutConstraint.activate([
            originalPriorityChip.topAnchor.constraint(equalTo: view.topAnchor),
            originalPriorityChip.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        self.originalPriorityChip = originalPriorityChip

        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .h4
        descLabel.textColor = .base500
        descLabel.numberOfLines = 1
        view.addSubview(descLabel)
        descLabelRightViewConstraint = descLabel.rightAnchor.constraint(equalTo: view.rightAnchor)
        descLabelRightViewConstraint.isActive = false
        descLabelRightPriorityChipConstraint = descLabel.rightAnchor.constraint(lessThanOrEqualTo: originalPriorityChip.leftAnchor, constant: -10)
        descLabelRightPriorityChipConstraint.isActive = false
        NSLayoutConstraint.activate([
            descLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
            descLabel.topAnchor.constraint(equalTo: view.topAnchor),
            descLabelRightViewConstraint,
            view.bottomAnchor.constraint(equalTo: descLabel.bottomAnchor)
        ])
        self.descLabel = descLabel

        let updatedAtLabel = UILabel()
        updatedAtLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedAtLabel.font = .body14Bold
        updatedAtLabel.textColor = .base500
        col.addArrangedSubview(updatedAtLabel)
        self.updatedAtLabel = updatedAtLabel

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
    }

    func configure(report: Report?, index: Int, selected: Bool) {
        guard let report = report else { return }

        checkbox.isChecked = selected

        if let pin = report.pin, !pin.isEmpty {
            tagLabel.text = "#\(pin)"
        }

        let priority = TriagePriority(rawValue: report.filterPriority ?? -1) ?? .unknown
        priorityChip.color = priority.color
        priorityChip.setTitle(priority.description, for: .normal)

        if priority == .transported {
            let originalPriority = TriagePriority(rawValue: report.patient?.priority ?? -1) ?? .unknown
            originalPriorityChip.color = originalPriority.color
            originalPriorityChip.setTitle(originalPriority.description, for: .normal)
            originalPriorityChip.isHidden = false
            originalPriorityChipWidthConstraint.isActive = true
            descLabelRightViewConstraint.isActive = false
            descLabelRightPriorityChipConstraint.isActive = true
            checkbox.isHidden = true
        } else {
            originalPriorityChip.isHidden = true
            originalPriorityChipWidthConstraint.isActive = false
            descLabelRightPriorityChipConstraint.isActive = false
            descLabelRightViewConstraint.isActive = true
            checkbox.isHidden = false
        }

        descLabel.text = report.description
        updatedAtLabel.text = report.updatedAt?.asRelativeString() ?? " "
    }
}
