//
//  IncidentTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 10/29/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import PRKit

class IncidentTableViewCell: UITableViewCell {
    weak var containerView: UIView!
    weak var numberLabel: UILabel!
    weak var addressLabel: UILabel!
    weak var dateLabel: UILabel!
    weak var timeLabel: UILabel!
    var timeLabelConstraints: [NSLayoutConstraint] = []
    weak var chevronImageView: UIImageView!

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
        let containerViewWidthConstraint = containerView.widthAnchor.constraint(equalToConstant: isCompact ? 300 : 860)
        containerViewWidthConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: isCompact ? 28 : 22),
            containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            containerView.leftAnchor.constraint(greaterThanOrEqualTo: contentView.leftAnchor, constant: 20),
            containerView.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -20),
            containerViewWidthConstraint,
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: isCompact ? 28 : 22)
        ])
        self.containerView = containerView

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
                dateLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 540)
            ])
        }
        self.dateLabel = dateLabel

        let timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .h4
        timeLabel.textColor = .base500
        containerView.addSubview(timeLabel)
        self.timeLabel = timeLabel
        updateTimeLabelConstraints()

        let chevronImageView = UIImageView()
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(named: "ChevronRight40px", in: PRKitBundle.instance, compatibleWith: nil)
        chevronImageView.tintColor = .base500
        containerView.addSubview(chevronImageView)
        NSLayoutConstraint.activate([
            chevronImageView.centerYAnchor.constraint(equalTo: numberLabel.centerYAnchor),
            chevronImageView.rightAnchor.constraint(equalTo: containerView.rightAnchor)
        ])

        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .base300
        contentView.addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            separatorView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ])

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

            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged),
                                                   name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }

    deinit {
        if traitCollection.horizontalSizeClass == .regular {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }

    func updateTimeLabelConstraints() {
        NSLayoutConstraint.deactivate(timeLabelConstraints)
        timeLabelConstraints.removeAll()

        let isCompact = traitCollection.horizontalSizeClass == .compact
        let orientation = UIApplication.interfaceOrientation()
        if isCompact {
            timeLabelConstraints.append(timeLabel.firstBaselineAnchor.constraint(equalTo: dateLabel.firstBaselineAnchor))
            timeLabelConstraints.append(timeLabel.leftAnchor.constraint(equalTo: dateLabel.rightAnchor, constant: 10))
        } else {
            if orientation == .landscapeLeft || orientation == .landscapeRight {
                timeLabelConstraints.append(timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor))
                timeLabelConstraints.append(timeLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 700))
            } else {
                timeLabelConstraints.append(timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor))
                timeLabelConstraints.append(timeLabel.leftAnchor.constraint(equalTo: dateLabel.leftAnchor))
            }
        }
        NSLayoutConstraint.activate(timeLabelConstraints)
    }

    @objc func orientationChanged() {
        updateTimeLabelConstraints()
    }
}
