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
    weak var mciChip: Chip!
    weak var addressLabel: UILabel!
    weak var dateLabel: UILabel!
    weak var timeLabel: UILabel!
    weak var reportsCountChip: Chip!
    weak var chevronImageView: UIImageView!

    var numberWidthConstraint: NSLayoutConstraint!
    var addressLeftConstraint: NSLayoutConstraint!
    var addressWidthConstraint: NSLayoutConstraint!
    var dateLeftConstraint: NSLayoutConstraint!

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
    var reportsCount: Int? {
        get { return Int(reportsCountChip.title(for: .normal) ?? "") }
        set {
            if let newValue = newValue, newValue > 0 {
                reportsCountChip.setTitle("\(newValue)", for: .normal)
                reportsCountChip.isHidden = false
            } else {
                reportsCountChip.isHidden = true
            }
        }
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

        backgroundView = UIView()
        selectedBackgroundView = UIView()

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        if isCompact {
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
                containerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
                containerView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
                contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 28)
            ])
        } else {
            let containerViewWidthConstraint = containerView.widthAnchor.constraint(equalToConstant: 860)
            containerViewWidthConstraint.priority = .defaultHigh
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
                containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                containerView.leftAnchor.constraint(greaterThanOrEqualTo: contentView.leftAnchor, constant: 20),
                containerView.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -20),
                containerViewWidthConstraint,
                contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 22)
            ])
        }
        self.containerView = containerView

        let numberLabel = UILabel()
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.font = .h2Bold
        numberLabel.textColor = .headingText
        numberLabel.lineBreakMode = .byTruncatingMiddle
        containerView.addSubview(numberLabel)
        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            numberLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor)
        ])
        self.numberLabel = numberLabel

        let chevronImageView = UIImageView()
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(named: "ChevronRight40px", in: PRKitBundle.instance, compatibleWith: nil)
        chevronImageView.tintColor = .labelText
        chevronImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        chevronImageView.setContentHuggingPriority(.required, for: .horizontal)
        containerView.addSubview(chevronImageView)
        NSLayoutConstraint.activate([
            chevronImageView.centerYAnchor.constraint(equalTo: numberLabel.centerYAnchor, constant: 2),
            chevronImageView.rightAnchor.constraint(equalTo: containerView.rightAnchor)
        ])

        let chipStackView = UIStackView()
        chipStackView.translatesAutoresizingMaskIntoConstraints = false
        chipStackView.axis = .vertical
        chipStackView.alignment = .fill
        chipStackView.spacing = 4
        containerView.addSubview(chipStackView)
        if isCompact {
            NSLayoutConstraint.activate([
                chipStackView.rightAnchor.constraint(equalTo: chevronImageView.leftAnchor),
                chipStackView.topAnchor.constraint(equalTo: chevronImageView.topAnchor, constant: 1),
                chipStackView.leftAnchor.constraint(equalTo: numberLabel.rightAnchor, constant: 10)
            ])
        } else {
            NSLayoutConstraint.activate([
                chipStackView.rightAnchor.constraint(equalTo: chevronImageView.leftAnchor),
                chipStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])
        }

        let reportsCountChip = Chip()
        reportsCountChip.translatesAutoresizingMaskIntoConstraints = false
        reportsCountChip.color = .headingText
        reportsCountChip.setTitleColor(.white, for: .normal)
        reportsCountChip.isUserInteractionEnabled = false
        reportsCountChip.setContentCompressionResistancePriority(.required, for: .horizontal)
        reportsCountChip.setContentHuggingPriority(.required, for: .horizontal)
        chipStackView.addArrangedSubview(reportsCountChip)
        self.reportsCountChip = reportsCountChip

        let mciChip = Chip()
        mciChip.translatesAutoresizingMaskIntoConstraints = false
        mciChip.color = .brandSecondary800
        mciChip.isUserInteractionEnabled = false
        mciChip.setTitle("MCI".localized, for: .normal)
        chipStackView.addArrangedSubview(mciChip)
        self.mciChip = mciChip

        let addressLabel = UILabel()
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = .h4
        addressLabel.textColor = .text
        addressLabel.numberOfLines = 0
        containerView.addSubview(addressLabel)
        if isCompact {
            NSLayoutConstraint.activate([
                addressLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor),
                addressLabel.leftAnchor.constraint(equalTo: numberLabel.leftAnchor),
                addressLabel.rightAnchor.constraint(equalTo: chipStackView.leftAnchor, constant: -4)
            ])
        } else {
            numberWidthConstraint = numberLabel.widthAnchor.constraint(equalToConstant: 190)
            addressLeftConstraint = addressLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 200)
            addressWidthConstraint = addressLabel.widthAnchor.constraint(equalToConstant: 250)
            NSLayoutConstraint.activate([
                numberWidthConstraint,
                addressLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
                addressLeftConstraint,
                addressWidthConstraint
            ])
        }
        self.addressLabel = addressLabel

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .h4
        dateLabel.textColor = .labelText
        containerView.addSubview(dateLabel)
        if isCompact {
            NSLayoutConstraint.activate([
                dateLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor),
                dateLabel.leftAnchor.constraint(equalTo: addressLabel.leftAnchor)
            ])
        } else {
            dateLeftConstraint = dateLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 460)
            NSLayoutConstraint.activate([
                dateLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
                dateLeftConstraint
            ])
        }
        self.dateLabel = dateLabel

        let timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .h4
        timeLabel.textColor = .labelText
        containerView.addSubview(timeLabel)
        self.timeLabel = timeLabel
        if isCompact {
            NSLayoutConstraint.activate([
                timeLabel.firstBaselineAnchor.constraint(equalTo: dateLabel.firstBaselineAnchor),
                timeLabel.leftAnchor.constraint(equalTo: dateLabel.rightAnchor, constant: 10)
            ])
        } else {
            NSLayoutConstraint.activate([
                timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor),
                timeLabel.leftAnchor.constraint(equalTo: dateLabel.leftAnchor)
            ])
        }

        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .disabledBorder
        contentView.addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            separatorView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 2)
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

        orientationChanged()
    }

    deinit {
        if traitCollection.horizontalSizeClass == .regular {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }

    @objc func orientationChanged() {
        guard traitCollection.horizontalSizeClass == .regular else { return }
        let orientation = UIApplication.interfaceOrientation()
        switch orientation {
        case .portrait, .portraitUpsideDown:
            numberWidthConstraint.constant = 190
            addressLeftConstraint.constant = 200
            addressWidthConstraint.constant = 250
            dateLeftConstraint.constant = 460
        case .landscapeLeft, .landscapeRight:
            numberWidthConstraint.constant = 220
            addressLeftConstraint.constant = 260
            addressWidthConstraint.constant = 280
            dateLeftConstraint.constant = 580
        default:
            break
        }
    }

    func update(from incident: Incident) {
        number = "#\(incident.number ?? "")"
        address = incident.scene?.address
        let isMCI = incident.scene?.isMCI ?? false
        let isActiveMCI = isMCI && (incident.scene?.isActive ?? false)
        let backgroundColor: UIColor = isActiveMCI ? .activeBackground : .background
        backgroundView?.backgroundColor = backgroundColor
        selectedBackgroundView?.backgroundColor = backgroundColor.colorWithBrightnessMultiplier(multiplier: 0.8)
        numberLabel.textColor = isMCI ? .activeHeadingText : .headingText
        addressLabel.textColor = isActiveMCI ? .activeText : .text
        dateLabel.textColor = isActiveMCI ? .activeLabelText : .labelText
        timeLabel.textColor = isActiveMCI ? .activeLabelText : .labelText
        if incident.dispatches.count > 0 {
            let dispatch = incident.dispatches.sorted(byKeyPath: "dispatchedAt", ascending: true)[0]
            date = dispatch.dispatchedAt?.asDateString()
            time = dispatch.dispatchedAt?.asTimeString()
        } else {
            date = incident.createdAt?.asDateString()
            time = incident.createdAt?.asTimeString()
        }
        mciChip.isHidden = !isMCI
        reportsCountChip.color = isMCI ? .brandSecondary800 : .headingText
        reportsCount = incident.reportsCount
    }
}
