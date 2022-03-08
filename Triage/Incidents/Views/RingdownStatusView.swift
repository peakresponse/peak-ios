//
//  RingdownStatusView.swift
//  Triage
//
//  Created by Francis Li on 3/8/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import PRKit
import UIKit

class RingdownStatusView: UIView {
    weak var hospitalNameLabel: UILabel!
    weak var ringdownStatusLabel: UILabel!
    weak var ringdownStatusChip: Chip!
    weak var arrivalLabel: UILabel!
    weak var arrivalTimeLabel: UILabel!
    weak var buttonsView: UIStackView!
    weak var redirectButton: PRKit.Button!
    weak var cancelButton: PRKit.Button!

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

        bottomAnchor.constraint(equalTo: buttonsView.bottomAnchor, constant: 16).isActive = true
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
    }
}
