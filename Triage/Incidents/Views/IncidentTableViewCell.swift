//
//  IncidentTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 10/29/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit

class IncidentTableViewCell: UITableViewCell {
    weak var numberLabel: UILabel!
    weak var addressLabel: UILabel!
    weak var dateLabel: UILabel!
    weak var timeLabel: UILabel!

    var number: String? {
        get { return numberLabel.text }
        set { numberLabel.text = newValue }
    }
    var address: String? {
        get { return addressLabel.text }
        set { addressLabel.text = newValue }
    }
    var date: String? {
        get { return dateLabel.text }
        set { dateLabel.text = newValue }
    }
    var time: String? {
        get { return timeLabel.text }
        set { timeLabel.text = newValue }
    }

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        let isCompact = traitCollection.horizontalSizeClass == .compact

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: isCompact ? 28 : 22),
            containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: isCompact ? 28 : 22)
        ])
        if isCompact {
            NSLayoutConstraint.activate([
                containerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
                containerView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)
            ])
        } else {
            let widthConstraint = containerView.widthAnchor.constraint(equalToConstant: 860)
            widthConstraint.priority = .defaultHigh
            NSLayoutConstraint.activate([
                containerView.leftAnchor.constraint(greaterThanOrEqualTo: contentView.leftAnchor, constant: 20),
                containerView.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -20),
                widthConstraint
            ])
        }

        let numberLabel = UILabel()
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.font = .h2Bold
        numberLabel.textColor = .brandPrimary600
        containerView.addSubview(numberLabel)
        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            numberLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor)
        ])
        self.numberLabel = numberLabel

        let addressLabel = UILabel()
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = .h4
        addressLabel.textColor = .base800
        addressLabel.numberOfLines = 0
        containerView.addSubview(addressLabel)
        if isCompact {
            NSLayoutConstraint.activate([
                addressLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor),
                addressLabel.leftAnchor.constraint(equalTo: numberLabel.leftAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                addressLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
                addressLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 260)
            ])
        }
        self.addressLabel = addressLabel

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .h4
        dateLabel.textColor = .base500
        containerView.addSubview(dateLabel)
        if isCompact {
            NSLayoutConstraint.activate([
                dateLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor),
                dateLabel.leftAnchor.constraint(equalTo: addressLabel.leftAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                dateLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
                dateLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 500)
            ])
        }
        self.dateLabel = dateLabel

        let timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .h4
        timeLabel.textColor = .base500
        containerView.addSubview(timeLabel)
        if isCompact {
            NSLayoutConstraint.activate([
                timeLabel.firstBaselineAnchor.constraint(equalTo: dateLabel.firstBaselineAnchor),
                timeLabel.leftAnchor.constraint(equalTo: dateLabel.rightAnchor, constant: 10)
            ])
        } else {
            NSLayoutConstraint.activate([
                timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
                timeLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 660)
            ])
        }
        self.timeLabel = timeLabel

        if isCompact {
            NSLayoutConstraint.activate([
                containerView.bottomAnchor.constraint(equalTo: dateLabel.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: numberLabel.bottomAnchor),
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: addressLabel.bottomAnchor),
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: dateLabel.bottomAnchor),
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: timeLabel.bottomAnchor)
            ])
        }
    }
}
