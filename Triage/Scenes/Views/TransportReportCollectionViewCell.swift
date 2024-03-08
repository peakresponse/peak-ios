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
    weak var mciView: UIView!
    weak var priorityChip: Chip!
    weak var tagLabel: UILabel!
    weak var descLabel: UILabel!
    weak var updatedAtLabel: UILabel!
    weak var vr: UIView!

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

        let checkbox = Checkbox()
        checkbox.isUserInteractionEnabled = false
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            checkbox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        self.checkbox = checkbox

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .fill
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leftAnchor.constraint(equalTo: checkbox.rightAnchor, constant: 12),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        let mciView = UIView()
        mciView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(mciView)
        self.mciView = mciView

        let priorityChip = Chip()
        priorityChip.translatesAutoresizingMaskIntoConstraints = false
        priorityChip.isUserInteractionEnabled = false
        mciView.addSubview(priorityChip)
        NSLayoutConstraint.activate([
            priorityChip.topAnchor.constraint(equalTo: mciView.topAnchor),
            priorityChip.rightAnchor.constraint(equalTo: mciView.rightAnchor),
            mciView.bottomAnchor.constraint(equalTo: priorityChip.bottomAnchor)
        ])
        self.priorityChip = priorityChip

        let tagLabel = UILabel()
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.font = .h3SemiBold
        tagLabel.textColor = .base800
        mciView.addSubview(tagLabel)
        NSLayoutConstraint.activate([
            tagLabel.leftAnchor.constraint(equalTo: mciView.leftAnchor),
            tagLabel.centerYAnchor.constraint(equalTo: priorityChip.centerYAnchor),
            tagLabel.rightAnchor.constraint(lessThanOrEqualTo: priorityChip.leftAnchor, constant: -10)
        ])
        self.tagLabel = tagLabel

        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .h4
        descLabel.textColor = .base500
        stackView.addArrangedSubview(descLabel)
        self.descLabel = descLabel

        let updatedAtLabel = UILabel()
        updatedAtLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedAtLabel.font = .body14Bold
        updatedAtLabel.textColor = .base500
        stackView.addArrangedSubview(updatedAtLabel)
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

    func configure(report: Report?, index: Int, selected: Bool) {
        guard let report = report else { return }

        checkbox.isChecked = selected

        if let pin = report.pin, !pin.isEmpty {
            tagLabel.text = "#\(pin)"
        }

        let priority = TriagePriority(rawValue: report.filterPriority ?? -1) ?? .unknown
        priorityChip.color = priority.color
        priorityChip.setTitle(priority.description, for: .normal)

        descLabel.text = report.description
        updatedAtLabel.text = report.updatedAt?.asRelativeString() ?? " "

        vr.isHidden = traitCollection.horizontalSizeClass == .compact || !index.isMultiple(of: 2)
    }
}
