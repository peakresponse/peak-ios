//
//  SceneSummaryHeaderView.swift
//  Triage
//
//  Created by Francis Li on 9/14/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class SceneSummaryHeaderView: UIView {
    weak var nameLabel: UILabel!
    weak var descLabel: UILabel!
    weak var dateLabel: UILabel!
    weak var dateValueLabel: UILabel!
    weak var timeLabel: UILabel!
    weak var timeValueLabel: UILabel!
    weak var locationLabel: UILabel!
    weak var locationValueLabel: UILabel!

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
        backgroundColor = .bgBackground

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .copyLBold
        nameLabel.textColor = .mainGrey
        nameLabel.numberOfLines = 0
        addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            nameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            nameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -22)
        ])
        self.nameLabel = nameLabel

        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .copySRegular
        descLabel.textColor = .mainGrey
        descLabel.numberOfLines = 0
        addSubview(descLabel)
        NSLayoutConstraint.activate([
            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            descLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            descLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor)
        ])
        self.descLabel = descLabel

        let dateLabel = createLabel()
        dateLabel.text = "SceneSummaryHeaderView.dateLabel".localized
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 10),
            dateLabel.leftAnchor.constraint(equalTo: descLabel.leftAnchor)
        ])
        self.dateLabel = dateLabel
        self.dateValueLabel = createValueLabel(for: dateLabel)

        let timeLabel = createLabel()
        timeLabel.text = "SceneSummaryHeaderView.timeLabel".localized
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor),
            timeLabel.leftAnchor.constraint(equalTo: dateLabel.leftAnchor)
        ])
        self.timeLabel = timeLabel
        self.timeValueLabel = createValueLabel(for: timeLabel)

        let locationLabel = createLabel()
        locationLabel.text = "SceneSummaryHeaderView.locationLabel".localized
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor),
            locationLabel.leftAnchor.constraint(equalTo: timeLabel.leftAnchor)
        ])
        self.locationLabel = locationLabel
        self.locationValueLabel = createValueLabel(for: locationLabel)

        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 22)
        ])
    }

    private func createLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copySBold
        label.textColor = .mainGrey
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        addSubview(label)
        return label
    }

    private func createValueLabel(for label: UILabel) -> UILabel {
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .copySRegular
        valueLabel.textColor = .mainGrey
        addSubview(valueLabel)
        NSLayoutConstraint.activate([
            valueLabel.firstBaselineAnchor.constraint(equalTo: label.firstBaselineAnchor),
            valueLabel.leftAnchor.constraint(equalTo: label.rightAnchor),
            valueLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -22)
        ])
        return valueLabel
    }

    func configure(from scene: Scene) {
        nameLabel.text = scene.name?.isEmpty ?? true ? " " : scene.name
        descLabel.text = scene.desc?.isEmpty ?? true ? " " : scene.desc
        dateValueLabel.text = scene.createdAt?.asDateString()
        timeValueLabel.text = scene.createdAt?.asTimeString()
        locationValueLabel.text = scene.latLngString
    }
}
