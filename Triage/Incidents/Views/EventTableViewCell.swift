//
//  EventTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 5/5/25.
//  Copyright © 2025 Francis Li. All rights reserved.
//

import UIKit
import PRKit

class EventTableViewCell: UITableViewCell {
    weak var containerView: UIView!
    weak var nameLabel: UILabel!
    weak var venueLabel: UILabel!
    weak var dateLabel: UILabel!
    weak var timeLabel: UILabel!
    weak var chevronImageView: UIImageView!

    var nameWidthConstraint: NSLayoutConstraint!
    var venueLeftConstraint: NSLayoutConstraint!
    var venueWidthConstraint: NSLayoutConstraint!
    var dateLeftConstraint: NSLayoutConstraint!

    var name: String? {
        get { return nameLabel.text }
        set { nameLabel.text = newValue }
    }
    var venue: String? {
        get { return venueLabel.text }
        set { venueLabel.text = newValue }
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

        backgroundView = UIView()
        backgroundView?.backgroundColor = .background
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .background.colorWithBrightnessMultiplier(multiplier: 0.8)

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

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .h3SemiBold
        nameLabel.textColor = .headingText
        nameLabel.lineBreakMode = .byTruncatingMiddle
        containerView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            nameLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor)
        ])
        self.nameLabel = nameLabel

        let chevronImageView = UIImageView()
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(named: "ChevronRight40px", in: PRKitBundle.instance, compatibleWith: nil)
        chevronImageView.tintColor = .labelText
        chevronImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        chevronImageView.setContentHuggingPriority(.required, for: .horizontal)
        containerView.addSubview(chevronImageView)
        NSLayoutConstraint.activate([
            chevronImageView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 2),
            chevronImageView.rightAnchor.constraint(equalTo: containerView.rightAnchor)
        ])

        let venueLabel = UILabel()
        venueLabel.translatesAutoresizingMaskIntoConstraints = false
        venueLabel.font = .h4
        venueLabel.textColor = .text
        venueLabel.numberOfLines = 0
        containerView.addSubview(venueLabel)
        if isCompact {
            NSLayoutConstraint.activate([
                nameLabel.rightAnchor.constraint(equalTo: chevronImageView.leftAnchor, constant: -10),
                venueLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
                venueLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
                venueLabel.rightAnchor.constraint(equalTo: chevronImageView.leftAnchor, constant: -4)
            ])
        } else {
            nameWidthConstraint = nameLabel.widthAnchor.constraint(equalToConstant: 190)
            venueLeftConstraint = venueLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 200)
            venueWidthConstraint = venueLabel.widthAnchor.constraint(equalToConstant: 250)
            NSLayoutConstraint.activate([
                nameWidthConstraint,
                venueLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
                venueLeftConstraint,
                venueWidthConstraint
            ])
        }
        self.venueLabel = venueLabel

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .h4
        dateLabel.textColor = .labelText
        containerView.addSubview(dateLabel)
        if isCompact {
            NSLayoutConstraint.activate([
                dateLabel.topAnchor.constraint(equalTo: venueLabel.bottomAnchor),
                dateLabel.leftAnchor.constraint(equalTo: venueLabel.leftAnchor)
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
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: nameLabel.bottomAnchor),
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: venueLabel.bottomAnchor),
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
            nameWidthConstraint.constant = 190
            venueLeftConstraint.constant = 200
            venueWidthConstraint.constant = 250
            dateLeftConstraint.constant = 460
        case .landscapeLeft, .landscapeRight:
            nameWidthConstraint.constant = 220
            venueLeftConstraint.constant = 260
            venueWidthConstraint.constant = 280
            dateLeftConstraint.constant = 580
        default:
            break
        }
    }

    func update(from event: Event) {
        name = event.name
        venue = event.venue?.name
        date = event.start?.asDateString()
        time = event.start?.asTimeString()
    }
}
