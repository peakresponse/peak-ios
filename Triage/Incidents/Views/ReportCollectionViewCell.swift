//
//  ReportCollectionViewCell.swift
//  Triage
//
//  Created by Francis Li on 1/5/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import PRKit
import UIKit

class ReportCollectionViewCell: UICollectionViewCell {
    weak var mciView: UIView!
    weak var priorityChip: Chip!
    weak var originalPriorityChip: Chip!
    weak var tagLabel: UILabel!
    weak var ageLabel: UILabel!
    weak var genderLabel: UILabel!
    weak var nameLabel: UILabel!
    weak var unitLabel: UILabel!
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

        let chevronImageView = UIImageView()
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(named: "ChevronRight40px", in: PRKitBundle.instance, compatibleWith: nil)
        chevronImageView.tintColor = .base500
        contentView.addSubview(chevronImageView)
        NSLayoutConstraint.activate([
            chevronImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            chevronImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 40)
        ])

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            stackView.rightAnchor.constraint(equalTo: chevronImageView.leftAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        let mciView = UIView()
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

        let originalPriorityChip = Chip()
        originalPriorityChip.isHidden = true
        originalPriorityChip.translatesAutoresizingMaskIntoConstraints = false
        originalPriorityChip.isUserInteractionEnabled = false
        mciView.addSubview(originalPriorityChip)
        NSLayoutConstraint.activate([
            originalPriorityChip.topAnchor.constraint(equalTo: priorityChip.bottomAnchor, constant: 4),
            originalPriorityChip.leftAnchor.constraint(equalTo: priorityChip.leftAnchor),
            originalPriorityChip.rightAnchor.constraint(equalTo: mciView.rightAnchor)
        ])
        self.originalPriorityChip = originalPriorityChip

        let tagLabel = UILabel()
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.font = .h3SemiBold
        tagLabel.textColor = .base800
        mciView.addSubview(tagLabel)
        NSLayoutConstraint.activate([
            tagLabel.leftAnchor.constraint(equalTo: mciView.leftAnchor),
            tagLabel.centerYAnchor.constraint(equalTo: priorityChip.centerYAnchor),
            tagLabel.rightAnchor.constraint(lessThanOrEqualTo: priorityChip.leftAnchor)
        ])
        self.tagLabel = tagLabel

        let unitLabel = UILabel()
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.font = .h4
        unitLabel.textColor = .base500
        unitLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Response.unitNumber".localized): ", text: "")
        unitLabel.numberOfLines = 2
        stackView.addArrangedSubview(unitLabel)
        self.unitLabel = unitLabel

        let ageLabel = UILabel()
        ageLabel.translatesAutoresizingMaskIntoConstraints = false
        ageLabel.font = .h4
        ageLabel.textColor = .base500
        ageLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Patient.age".localized): ", text: "")
        stackView.addArrangedSubview(ageLabel)
        self.ageLabel = ageLabel

        let genderLabel = UILabel()
        genderLabel.translatesAutoresizingMaskIntoConstraints = false
        genderLabel.font = .h4
        genderLabel.textColor = .base500
        genderLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Patient.gender".localized): ", text: "")
        stackView.addArrangedSubview(genderLabel)
        self.genderLabel = genderLabel

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .h4
        nameLabel.textColor = .base500
        nameLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Patient.fullName".localized): ", text: "")
        stackView.addArrangedSubview(nameLabel)
        self.nameLabel = nameLabel

        let updatedAtLabel = UILabel()
        updatedAtLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedAtLabel.font = .h4
        updatedAtLabel.textColor = .base500
        updatedAtLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Patient.updatedAt".localized): ", text: "")
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

    func configure(report: Report?, index: Int) {
        guard let report = report else { return }
        let isMCI = report.scene?.isMCI ?? false
        mciView.isHidden = !isMCI
        if let pin = report.pin, !pin.isEmpty {
            tagLabel.text = "#\(pin)"
        }
        if isMCI {
            let priority = TriagePriority(rawValue: report.filterPriority ?? -1) ?? .unknown
            priorityChip.color = priority.color
            priorityChip.setTitle(priority.description, for: .normal)

            if priority == .transported {
                let originalPriority = TriagePriority(rawValue: report.patient?.priority ?? -1) ?? .unknown
                originalPriorityChip.color = originalPriority.color
                originalPriorityChip.setTitle(originalPriority.description, for: .normal)
                originalPriorityChip.isHidden = false
            } else {
                originalPriorityChip.isHidden = true
            }
        }
        if !isMCI, let unitNumber = report.response?.unitNumber, !unitNumber.isEmpty {
            unitLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Response.unitNumber".localized): ", text: "\(unitNumber)\n")
            unitLabel.isHidden = false
        } else {
            unitLabel.isHidden = true
        }
        if let ageString = report.patient?.ageString, !ageString.isEmpty {
            ageLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Patient.age".localized): ", text: ageString)
            ageLabel.isHidden = false
        } else {
            ageLabel.isHidden = true
        }
        if let genderString = report.patient?.genderString, !genderString.isEmpty {
            genderLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Patient.gender".localized): ", text: genderString)
            genderLabel.isHidden = false
        } else {
            genderLabel.isHidden = true
        }
        if let fullName = report.patient?.fullName, !fullName.isEmpty {
            nameLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Patient.fullName".localized): ", text: fullName)
            nameLabel.isHidden = false
        } else {
            nameLabel.isHidden = true
        }
        if let updatedAt = report.updatedAt {
            updatedAtLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Patient.updatedAt".localized): ", text: updatedAt.asRelativeString())
            updatedAtLabel.isHidden = false
        } else {
            updatedAtLabel.isHidden = true
        }
        vr.isHidden = traitCollection.horizontalSizeClass == .compact || !index.isMultiple(of: 2)
    }
}
