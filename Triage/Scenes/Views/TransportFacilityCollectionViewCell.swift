//
//  TransportFacilityCollectionViewCell.swift
//  Triage
//
//  Created by Francis Li on 3/8/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
internal import RealmSwift
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
        label.textColor = .labelText
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            label.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor),
            label.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor)
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
            stackView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
        self.stackView = stackView

        for priority in [TriagePriority.immediate, TriagePriority.delayed, TriagePriority.minimal] {
            let view = UIView()
            view.backgroundColor = .textBackground
            view.layer.cornerRadius = 8
            view.layer.borderWidth = 2
            view.layer.borderColor = priority.color.cgColor
            view.heightAnchor.constraint(equalToConstant: 44).isActive = true
            stackView.addArrangedSubview(view)

            let countLabel = UILabel()
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            countLabel.font = .h4SemiBold
            countLabel.textColor = .text
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
            countLabel.textColor = .base800
            if let view = countLabel.superview, let priority = TriagePriority(rawValue: i) {
                view.backgroundColor = priority.lightenedColor
            }
        }
    }
}

class TransportFacilityCollectionViewCell: UICollectionViewCell {
    var facilityId: String?
    var facilityLocationCode: String?
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
        selectedBackgroundView.backgroundColor = .highlight
        self.selectedBackgroundView = selectedBackgroundView

        let checkbox = Checkbox()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.isUserInteractionEnabled = false
        checkbox.isRadioButton = true
        checkbox.isRadioButtonDeselectable = true
        checkbox.label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            checkbox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12)
        ])
        self.checkbox = checkbox

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .fill
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leftAnchor.constraint(equalTo: checkbox.rightAnchor, constant: 4),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])

        let facilityLabel = UILabel()
        facilityLabel.translatesAutoresizingMaskIntoConstraints = false
        facilityLabel.font = .h3SemiBold
        facilityLabel.textColor = .text
        facilityLabel.numberOfLines = 1
        facilityLabel.lineBreakMode = .byTruncatingTail
        stackView.addArrangedSubview(facilityLabel)
        self.facilityLabel = facilityLabel

        for labelText in ["TransportFacilityCollectionViewCell.row.capacity".localized,
                          "TransportFacilityCollectionViewCell.row.transported".localized,
                          "TransportFacilityCollectionViewCell.row.available".localized] {
            let row = CountRow()
            row.label.text = labelText
            stackView.addArrangedSubview(row)
            rows.append(row)
        }
        rows.last?.isHighlighted = true
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        var view = superview
        while !(view?.isKind(of: UICollectionView.self) ?? true) {
            view = view?.superview
        }
        if let collectionView = view as? UICollectionView,
           let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
           let inset = delegate.collectionView?(collectionView, layout: collectionView.collectionViewLayout, insetForSectionAt: 0) {
            let bounds = collectionView.bounds
            attributes.frame.size.width = bounds.size.width - inset.left - inset.right
            if traitCollection.horizontalSizeClass == .regular,
               let layout = (view as? UICollectionView)?.collectionViewLayout as? UICollectionViewFlowLayout {
                attributes.frame.size.width = floor((attributes.frame.size.width - layout.minimumInteritemSpacing) / 2)
            }
        }
        return attributes
    }

    func configure(from regionFacility: RegionFacility?, index: Int, isSelected: Bool) {
        checkbox.isChecked = isSelected
        facilityId = regionFacility?.facility?.id
        facilityLocationCode = regionFacility?.facility?.locationCode
        facilityLabel.text = regionFacility?.facility?.displayName
    }

    func updateCapacityCounts(from hospitalStatusUpdates: Results<HospitalStatusUpdate>?) {
        let row = rows[0]
        row.countLabels[0].text = "-"
        row.countLabels[1].text = "-"
        row.countLabels[2].text = "-"
        if let hospitalStatusUpdate = hospitalStatusUpdates?.filter("stateFacilityCode=%@", facilityLocationCode ?? "").first {
            row.countLabels[0].text = hospitalStatusUpdate.mciRedCapacity != nil ? "\(hospitalStatusUpdate.mciRedCapacity ?? 0)" : "-"
            row.countLabels[1].text = hospitalStatusUpdate.mciYellowCapacity != nil ? "\(hospitalStatusUpdate.mciYellowCapacity ?? 0)" : "-"
            row.countLabels[2].text = hospitalStatusUpdate.mciGreenCapacity != nil ? "\(hospitalStatusUpdate.mciGreenCapacity ?? 0)" : "-"
        }
        updateRemainingCounts()
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
        updateRemainingCounts()
    }

    func updateRemainingCounts() {
        for i in 0...2 {
            let capacityText = rows[0].countLabels[i].text ?? "-"
            let transportedText = rows[1].countLabels[i].text ?? "-"
            if capacityText != "-" && transportedText != "-", let capacity = Int(capacityText), let transported = Int(transportedText) {
                rows[2].countLabels[i].text = "\(capacity - transported)"
            } else {
                rows[2].countLabels[i].text = "-"
            }
        }
    }
}
