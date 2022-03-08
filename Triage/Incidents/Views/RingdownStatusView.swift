//
//  RingdownStatusView.swift
//  Triage
//
//  Created by Francis Li on 3/8/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import PRKit
import UIKit

class RingdownStatusRowView: UIView {
    weak var iconButton: UIButton!
    weak var topLine: UIView!
    weak var bottomLine: UIView!
    weak var label: UILabel!
    weak var timeLabel: UILabel!

    var labelText: String? {
        get { return label.text }
        set { label.text = newValue }
    }

    var isTopLineHidden: Bool {
        get { return topLine.isHidden }
        set { topLine.isHidden = newValue}
    }

    var isBottomLineHidden: Bool {
        get { return bottomLine.isHidden }
        set { bottomLine.isHidden = newValue}
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
        let iconButton = UIButton(type: .custom)
        iconButton.translatesAutoresizingMaskIntoConstraints = false
        iconButton.isUserInteractionEnabled = false
        iconButton.tintColor = .base300
        iconButton.setImage(UIImage(named: "NoCheck24px", in: PRKitBundle.instance, compatibleWith: nil), for: .normal)
        iconButton.setImage(UIImage(named: "Check24px", in: PRKitBundle.instance, compatibleWith: nil), for: .selected)
        addSubview(iconButton)
        NSLayoutConstraint.activate([
            iconButton.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            iconButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 24),
            iconButton.widthAnchor.constraint(equalToConstant: 24),
            iconButton.heightAnchor.constraint(equalToConstant: 24),
            bottomAnchor.constraint(equalTo: iconButton.bottomAnchor, constant: 24)
        ])
        self.iconButton = iconButton

        let topLine = UIView()
        topLine.translatesAutoresizingMaskIntoConstraints = false
        topLine.backgroundColor = .base300
        addSubview(topLine)
        NSLayoutConstraint.activate([
            topLine.topAnchor.constraint(equalTo: topAnchor),
            topLine.widthAnchor.constraint(equalToConstant: 2),
            topLine.centerXAnchor.constraint(equalTo: iconButton.centerXAnchor),
            topLine.bottomAnchor.constraint(equalTo: iconButton.topAnchor, constant: 1)
        ])
        self.topLine = topLine

        let bottomLine = UIView()
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        bottomLine.backgroundColor = .base300
        addSubview(bottomLine)
        NSLayoutConstraint.activate([
            bottomLine.topAnchor.constraint(equalTo: iconButton.bottomAnchor, constant: -1),
            bottomLine.widthAnchor.constraint(equalToConstant: 2),
            bottomLine.centerXAnchor.constraint(equalTo: iconButton.centerXAnchor),
            bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.bottomLine = bottomLine

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .h4SemiBold
        label.textColor = .base500
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leftAnchor.constraint(equalTo: iconButton.rightAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: iconButton.centerYAnchor)
        ])
        self.label = label

        let timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .body14Bold
        timeLabel.textColor = .base500
        addSubview(timeLabel)
        NSLayoutConstraint.activate([
            timeLabel.leftAnchor.constraint(equalTo: label.leftAnchor),
            timeLabel.topAnchor.constraint(equalTo: label.bottomAnchor)
        ])
        self.timeLabel = timeLabel
    }

    func setStatusDate(_ date: Date?) {
        if let date = date {
            timeLabel.text = date.asTimeString()
            timeLabel.isHidden = false
            label.textColor = .base800
            iconButton.isSelected = true
            iconButton.tintColor = .brandPrimary500
            topLine.backgroundColor = .brandPrimary500
            bottomLine.backgroundColor = .brandPrimary500
        } else {
            timeLabel.text = nil
            timeLabel.isHidden = true
            label.textColor = .base500
            iconButton.isSelected = false
            iconButton.tintColor = .base300
            topLine.backgroundColor = .base300
            bottomLine.backgroundColor = .base300
        }
    }
}

class RingdownStatusView: UIView {
    weak var hospitalNameLabel: UILabel!
    weak var ringdownStatusLabel: UILabel!
    weak var ringdownStatusChip: Chip!
    weak var arrivalLabel: UILabel!
    weak var arrivalTimeLabel: UILabel!
    weak var buttonsView: UIStackView!
    weak var redirectButton: PRKit.Button!
    weak var cancelButton: PRKit.Button!
    var statusRows: [RingdownStatusRowView] = []

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
        let hospitalNameLabel = UILabel()
        hospitalNameLabel.translatesAutoresizingMaskIntoConstraints = false
        hospitalNameLabel.font = .h3SemiBold
        hospitalNameLabel.textColor = .base800
        hospitalNameLabel.numberOfLines = 0
        addSubview(hospitalNameLabel)
        NSLayoutConstraint.activate([
            hospitalNameLabel.topAnchor.constraint(equalTo: topAnchor),
            hospitalNameLabel.leftAnchor.constraint(equalTo: leftAnchor),
            hospitalNameLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor)
        ])
        self.hospitalNameLabel = hospitalNameLabel

        let ringdownStatusLabel = UILabel()
        ringdownStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        ringdownStatusLabel.font = .h4
        ringdownStatusLabel.textColor = .base500
        ringdownStatusLabel.text = "RingdownStatusView.ringdownStatus".localized
        addSubview(ringdownStatusLabel)
        NSLayoutConstraint.activate([
            ringdownStatusLabel.topAnchor.constraint(equalTo: hospitalNameLabel.bottomAnchor, constant: 12),
            ringdownStatusLabel.leftAnchor.constraint(equalTo: hospitalNameLabel.leftAnchor)
        ])
        self.ringdownStatusLabel = ringdownStatusLabel

        let ringdownStatusChip = Chip()
        ringdownStatusChip.translatesAutoresizingMaskIntoConstraints = false
        ringdownStatusChip.isUserInteractionEnabled = false
        addSubview(ringdownStatusChip)
        NSLayoutConstraint.activate([
            ringdownStatusChip.centerYAnchor.constraint(equalTo: ringdownStatusLabel.centerYAnchor),
            ringdownStatusChip.leftAnchor.constraint(equalTo: ringdownStatusLabel.rightAnchor),
            ringdownStatusChip.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor)
        ])
        self.ringdownStatusChip = ringdownStatusChip

        let arrivalLabel = UILabel()
        arrivalLabel.translatesAutoresizingMaskIntoConstraints = false
        arrivalLabel.font = .h4
        arrivalLabel.textColor = .base500
        arrivalLabel.text = "RingdownStatusView.eta".localized
        addSubview(arrivalLabel)
        NSLayoutConstraint.activate([
            arrivalLabel.topAnchor.constraint(equalTo: ringdownStatusLabel.bottomAnchor, constant: 4),
            arrivalLabel.leftAnchor.constraint(equalTo: ringdownStatusLabel.leftAnchor)
        ])
        self.arrivalLabel = arrivalLabel

        let arrivalTimeLabel = UILabel()
        arrivalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        arrivalTimeLabel.font = .h4SemiBold
        arrivalTimeLabel.textColor = .base800
        addSubview(arrivalTimeLabel)
        NSLayoutConstraint.activate([
            arrivalTimeLabel.firstBaselineAnchor.constraint(equalTo: arrivalLabel.firstBaselineAnchor),
            arrivalTimeLabel.leftAnchor.constraint(equalTo: arrivalLabel.rightAnchor)
        ])
        self.arrivalTimeLabel = arrivalTimeLabel

        let buttonsView = UIStackView()
        buttonsView.translatesAutoresizingMaskIntoConstraints = false
        buttonsView.axis = .horizontal
        buttonsView.distribution = .fillEqually
        buttonsView.spacing = 20
        addSubview(buttonsView)
        NSLayoutConstraint.activate([
            buttonsView.topAnchor.constraint(equalTo: arrivalLabel.bottomAnchor, constant: 12),
            buttonsView.leftAnchor.constraint(equalTo: leftAnchor),
            buttonsView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        self.buttonsView = buttonsView

        let redirectButton = PRKit.Button()
        redirectButton.size = .small
        redirectButton.style = .secondary
        redirectButton.setTitle("Button.redirectPatient".localized, for: .normal)
        buttonsView.addArrangedSubview(redirectButton)
        self.redirectButton = redirectButton

        let cancelButton = PRKit.Button()
        cancelButton.size = .small
        cancelButton.style = .secondary
        cancelButton.setTitle("Button.cancelTransport".localized, for: .normal)
        buttonsView.addArrangedSubview(cancelButton)
        self.cancelButton = cancelButton

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: buttonsView.bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
        var prevRow: RingdownStatusRowView?
        for status in ["sent", "arrived", "offloaded", "returned"] {
            let statusRow = RingdownStatusRowView()
            statusRow.labelText = "RingdownStatusView.status.\(status)".localized
            statusRow.isTopLineHidden = prevRow == nil
            stackView.addArrangedSubview(statusRow)
            statusRows.append(statusRow)
            prevRow = statusRow
        }
        prevRow?.isBottomLineHidden = true
    }

    func update(from ringdown: Ringdown) {
        hospitalNameLabel.text = ringdown.hospitalName
        let timestamps = ringdown.timestamps
        ringdownStatusChip.color = .triageDelayedMedium
        if timestamps[RingdownStatus.confirmed.rawValue] != nil {
            ringdownStatusChip.setTitle("RingdownStatusView.status.confirmed".localized, for: .normal)
            ringdownStatusChip.color = .triageMinimalMedium
        } else if timestamps[RingdownStatus.received.rawValue] != nil {
            ringdownStatusChip.setTitle("RingdownStatusView.status.delivered".localized, for: .normal)
        } else {
            ringdownStatusChip.setTitle("RingdownStatusView.status.pending".localized, for: .normal)
        }
        if timestamps[RingdownStatus.arrived.rawValue] != nil {
            arrivalLabel.text = "RingdownStatusView.arrived".localized
        } else {
            arrivalLabel.text = "RingdownStatusView.eta".localized
        }
        if let arrivalDate = ringdown.arrivalDate {
            arrivalTimeLabel.text = arrivalDate.asTimeString()
        }
        statusRows[0].setStatusDate(ISO8601DateFormatter.date(from: timestamps[RingdownStatus.sent.rawValue]))
        statusRows[1].setStatusDate(ISO8601DateFormatter.date(from: timestamps[RingdownStatus.arrived.rawValue]))
        statusRows[2].setStatusDate(ISO8601DateFormatter.date(from: timestamps[RingdownStatus.offloaded.rawValue]))
        statusRows[3].setStatusDate(ISO8601DateFormatter.date(from: timestamps[RingdownStatus.returnedToService.rawValue]))
    }
}
