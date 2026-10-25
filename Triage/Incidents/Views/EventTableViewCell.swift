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

    var layoutTraitCollection: UITraitCollection?
    var layoutConstraints: [NSLayoutConstraint] = []
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

    // swiftlint:disable:next function_body_length
    func commonInit() {
        let isCompact = traitCollection.horizontalSizeClass == .compact

        backgroundView = UIView()
        backgroundView?.backgroundColor = .background
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .background.colorWithBrightnessMultiplier(multiplier: 0.8)

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
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
        self.chevronImageView = chevronImageView

        let venueLabel = UILabel()
        venueLabel.translatesAutoresizingMaskIntoConstraints = false
        venueLabel.font = .h4
        venueLabel.textColor = .text
        venueLabel.numberOfLines = 0
        containerView.addSubview(venueLabel)
        self.venueLabel = venueLabel

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .h4
        dateLabel.textColor = .labelText
        containerView.addSubview(dateLabel)
        self.dateLabel = dateLabel

        let timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .h4
        timeLabel.textColor = .labelText
        containerView.addSubview(timeLabel)
        self.timeLabel = timeLabel

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

        updateLayout()
        resizeLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateLayout()
        resizeLayout()
    }

    func update(from event: Event) {
        name = event.name
        venue = event.venue?.name
        date = event.start?.asDateString()
        time = event.start?.asTimeString()
    }

    func updateLayout(_ traitCollection: UITraitCollection? = nil) {
        let traitCollection = traitCollection ?? self.traitCollection
        guard traitCollection.horizontalSizeClass != layoutTraitCollection?.horizontalSizeClass else { return }
        layoutTraitCollection = traitCollection

        NSLayoutConstraint.deactivate(layoutConstraints)
        layoutConstraints.removeAll()

        let isCompact = traitCollection.horizontalSizeClass == .compact
        if isCompact {
            layoutConstraints.append(contentsOf: [
                containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
                containerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
                containerView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
                contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 28),
                nameLabel.rightAnchor.constraint(equalTo: chevronImageView.leftAnchor, constant: -10),
                venueLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
                venueLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
                venueLabel.rightAnchor.constraint(equalTo: chevronImageView.leftAnchor, constant: -4),
                dateLabel.topAnchor.constraint(equalTo: venueLabel.bottomAnchor),
                dateLabel.leftAnchor.constraint(equalTo: venueLabel.leftAnchor),
                timeLabel.firstBaselineAnchor.constraint(equalTo: dateLabel.firstBaselineAnchor),
                timeLabel.leftAnchor.constraint(equalTo: dateLabel.rightAnchor, constant: 10),
                containerView.bottomAnchor.constraint(equalTo: dateLabel.bottomAnchor)
            ])
        } else {
            let containerViewWidthConstraint = containerView.widthAnchor.constraint(equalToConstant: 860)
            containerViewWidthConstraint.priority = .defaultHigh
            nameWidthConstraint = nameLabel.widthAnchor.constraint(equalToConstant: 190)
            venueLeftConstraint = venueLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 200)
            venueWidthConstraint = venueLabel.widthAnchor.constraint(equalToConstant: 250)
            dateLeftConstraint = dateLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 460)
            layoutConstraints.append(contentsOf: [
                containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
                containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                containerView.leftAnchor.constraint(greaterThanOrEqualTo: contentView.leftAnchor, constant: 20),
                containerView.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -20),
                containerViewWidthConstraint,
                contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 22),
                nameWidthConstraint,
                venueLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
                venueLeftConstraint,
                venueWidthConstraint,
                dateLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
                dateLeftConstraint,
                timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor),
                timeLabel.leftAnchor.constraint(equalTo: dateLabel.leftAnchor),
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: nameLabel.bottomAnchor),
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: venueLabel.bottomAnchor),
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: dateLabel.bottomAnchor),
                containerView.bottomAnchor.constraint(greaterThanOrEqualTo: timeLabel.bottomAnchor)
            ])
        }

        NSLayoutConstraint.activate(layoutConstraints)
    }

    func resizeLayout(_ size: CGSize? = nil) {
        guard layoutTraitCollection?.horizontalSizeClass == .regular else { return }
        guard let size = size ?? screen?.bounds.size else { return }
        if size.width < size.height {
            nameWidthConstraint.constant = 190
            venueLeftConstraint.constant = 200
            venueWidthConstraint.constant = 250
            dateLeftConstraint.constant = 460
        } else {
            nameWidthConstraint.constant = 220
            venueLeftConstraint.constant = 260
            venueWidthConstraint.constant = 280
            dateLeftConstraint.constant = 580
        }
    }
}
