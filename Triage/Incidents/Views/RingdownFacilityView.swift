//
//  FacilityView.swift
//  Triage
//
//  Created by Francis Li on 3/3/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import PRKit
import UIKit

class RingdownFacilityCountView: UIView {
    weak var label: UILabel!
    weak var countLabel: UILabel!

    var labelText: String? {
        get { return label.text }
        set { label.text = newValue }
    }

    var countText: String? {
        get { return countLabel.text }
        set { countLabel.text = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // swiftlint:disable:next function_body_length
    private func commonInit() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .h4SemiBold
        label.textColor = .base500
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.leftAnchor.constraint(equalTo: leftAnchor),
            bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 4)
        ])
        self.label = label

        let countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = .h4SemiBold
        countLabel.textColor = .base800
        addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: label.topAnchor),
            countLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -4),
            countLabel.leftAnchor.constraint(greaterThanOrEqualTo: label.rightAnchor, constant: 4),
            countLabel.bottomAnchor.constraint(equalTo: label.bottomAnchor)
        ])
        self.countLabel = countLabel
    }
}

class RingdownFacilityView: UIView {
    weak var selectButton: PRKit.Button!
    weak var arrivalField: PRKit.TextField!
    weak var nameLabel: UILabel!
    weak var updatedAtLabel: UILabel!
    weak var statsStackView: UIStackView!
    var statCounts: [RingdownFacilityCountView] = []

    var nameText: String? {
        get { return nameLabel.text }
        set { nameLabel.text = newValue }
    }

    func setUpdatedAt(_ date: Date) {
        updatedAtLabel.text = date.asRelativeString()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // swiftlint:disable:next function_body_length
    private func commonInit() {
        let selectButton = PRKit.Button()
        selectButton.style = .secondary
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.setTitle("Button.select".localized, for: .normal)
        addSubview(selectButton)
        NSLayoutConstraint.activate([
            selectButton.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            selectButton.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        self.selectButton = selectButton

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .h3SemiBold
        nameLabel.textColor = .base800
        addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: selectButton.topAnchor),
            nameLabel.leftAnchor.constraint(equalTo: leftAnchor),
            nameLabel.rightAnchor.constraint(lessThanOrEqualTo: selectButton.leftAnchor, constant: -16)
        ])
        self.nameLabel = nameLabel

        let updatedAtLabel = UILabel()
        updatedAtLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedAtLabel.font = .body14Bold
        updatedAtLabel.textColor = .base500
        addSubview(updatedAtLabel)
        NSLayoutConstraint.activate([
            updatedAtLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            updatedAtLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            updatedAtLabel.rightAnchor.constraint(lessThanOrEqualTo: selectButton.leftAnchor, constant: -16)
        ])
        self.updatedAtLabel = updatedAtLabel

        let statsStackView = UIStackView()
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.axis = .vertical
        addSubview(statsStackView)
        NSLayoutConstraint.activate([
            statsStackView.topAnchor.constraint(equalTo: updatedAtLabel.bottomAnchor, constant: 16),
            statsStackView.leftAnchor.constraint(equalTo: updatedAtLabel.leftAnchor),
            statsStackView.widthAnchor.constraint(equalToConstant: 180),
            bottomAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 40)
        ])
        self.statsStackView = statsStackView

        var countView: RingdownFacilityCountView
        var hr: PixelRuleView

        countView = RingdownFacilityCountView()
        countView.translatesAutoresizingMaskIntoConstraints = false
        countView.labelText = "RingdownFacilityView.erBeds".localized
        statsStackView.addArrangedSubview(countView)

        hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        statsStackView.addArrangedSubview(hr)

        countView = RingdownFacilityCountView()
        countView.translatesAutoresizingMaskIntoConstraints = false
        countView.labelText = "RingdownFacilityView.psychBeds".localized
        statsStackView.addArrangedSubview(countView)

        hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        statsStackView.addArrangedSubview(hr)

        countView = RingdownFacilityCountView()
        countView.translatesAutoresizingMaskIntoConstraints = false
        countView.labelText = "RingdownFacilityView.enroute".localized
        statsStackView.addArrangedSubview(countView)

        hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        statsStackView.addArrangedSubview(hr)

        countView = RingdownFacilityCountView()
        countView.translatesAutoresizingMaskIntoConstraints = false
        countView.labelText = "RingdownFacilityView.waiting".localized
        statsStackView.addArrangedSubview(countView)
    }
}
