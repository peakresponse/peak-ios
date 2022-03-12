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
    weak var ageLabel: UILabel!
    weak var genderLabel: UILabel!
    weak var nameLabel: UILabel!
    weak var updatedAtLabel: UILabel!

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

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        let chevronImageView = UIImageView()
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(named: "ChevronRight40px", in: PRKitBundle.instance, compatibleWith: nil)
        chevronImageView.tintColor = .base500
        contentView.addSubview(chevronImageView)
        NSLayoutConstraint.activate([
            chevronImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            chevronImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 40),
            stackView.rightAnchor.constraint(equalTo: chevronImageView.leftAnchor)
        ])

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
                calculatedSize = CGSize(width: 375, height: 160)
            } else {
                calculatedSize = CGSize(width: superview?.frame.width ?? 375, height: 160)
            }
        }
        layoutAttributes.size = calculatedSize ?? .zero
        return layoutAttributes
    }

    func configure(report: Report?) {
        guard let report = report else { return }
        if let ageString = report.patient?.ageString {
            ageLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Patient.age".localized): ", text: ageString)
        }
        if let genderString = report.patient?.genderString {
            genderLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Patient.gender".localized): ", text: genderString)
        }
        if let fullName = report.patient?.fullName {
            nameLabel.setBoldPrefixedText(boldFont: .h4SemiBold, prefix: "\("Patient.fullName".localized): ", text: fullName)
        }
    }
}
