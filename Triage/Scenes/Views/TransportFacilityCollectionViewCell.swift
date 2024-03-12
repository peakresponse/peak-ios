//
//  TransportFacilityCollectionViewCell.swift
//  Triage
//
//  Created by Francis Li on 3/8/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import RealmSwift
import UIKit

private class CountRow: UIView {
    weak var label: UILabel!
    weak var stackView: UIStackView!
    var countLabels: [UILabel] = []
    var isHighlighted = false {
        didSet { updateHighlight() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .body14Bold
        label.textColor = .base500
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leftAnchor.constraint(equalTo: leftAnchor),
            label.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        self.label = label

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
        self.stackView = stackView

        for priority in [TriagePriority.immediate, TriagePriority.delayed, TriagePriority.minimal] {
            let view = UIView()
            view.layer.cornerRadius = 8
            view.layer.borderWidth = 2
            view.layer.borderColor = priority.color.cgColor
            view.heightAnchor.constraint(equalToConstant: 44).isActive = true
            stackView.addArrangedSubview(view)

            let countLabel = UILabel()
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            countLabel.font = .h4SemiBold
            countLabel.textColor = .base800
            countLabel.text = "-"
            view.addSubview(countLabel)
            NSLayoutConstraint.activate([
                countLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                countLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            countLabels.append(countLabel)
        }
    }

    func updateHighlight() {
        for (i, countLabel) in countLabels.enumerated() {
            if let view = countLabel.superview, let priority = TriagePriority(rawValue: i) {
                view.backgroundColor = priority.lightenedColor
            }
        }
    }
}

class TransportFacilityCollectionViewCell: UICollectionViewCell {
    var facilityId: String?
    weak var checkbox: Checkbox!
    weak var facilityLabel: UILabel!
    fileprivate var rows: [CountRow] = []

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
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .base100
        self.selectedBackgroundView = selectedBackgroundView

        let checkbox = Checkbox()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.isUserInteractionEnabled = false
        checkbox.isRadioButton = true
        checkbox.isRadioButtonDeselectable = true
        checkbox.label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            checkbox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16)
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

        let facilityLabel = UILabel()
        facilityLabel.translatesAutoresizingMaskIntoConstraints = false
        facilityLabel.font = .h3SemiBold
        facilityLabel.textColor = .base800
        facilityLabel.numberOfLines = 1
        facilityLabel.lineBreakMode = .byTruncatingTail
        stackView.addArrangedSubview(facilityLabel)
        self.facilityLabel = facilityLabel

        for labelText in ["TransportFacilityCollectionViewCell.row.capacity".localized, "TransportFacilityCollectionViewCell.row.transported".localized, "TransportFacilityCollectionViewCell.row.available".localized] {
            let row = CountRow()
            row.label.text = labelText
            stackView.addArrangedSubview(row)
            rows.append(row)
        }
        rows.last?.isHighlighted = true

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

    override func prepareForReuse() {
        super.prepareForReuse()
        calculatedSize = nil
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if calculatedSize == nil {
            if traitCollection.horizontalSizeClass == .regular {
                calculatedSize = CGSize(width: 372, height: 276)
            } else {
                calculatedSize = CGSize(width: superview?.frame.width ?? 375, height: 276)
            }
        }
        layoutAttributes.size = calculatedSize ?? .zero
        return layoutAttributes
    }

    func configure(from regionFacility: RegionFacility?, index: Int, isSelected: Bool) {
        checkbox.isChecked = isSelected
        facilityId = regionFacility?.facility?.id
        facilityLabel.text = regionFacility?.facility?.displayName
    }

    func updateTransportedCounts(from reports: Results<Report>?) {
        if let facilityId = facilityId, rows.count > 1 {
            let row = rows[1]
            for (i, priority) in [TriagePriority.immediate, TriagePriority.delayed, TriagePriority.minimal].enumerated() {
                if let count = reports?.filter("patient.priority=%d AND disposition.destinationFacility.id=%@", priority.rawValue, facilityId).count {
                    row.countLabels[i].text = "\(count)"
                } else {
                    row.countLabels[i].text = "-"
                }
            }
        }
    }
}
