//
//  PriorityTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 10/4/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@objc protocol PriorityTableViewCellDelegate {
    @objc optional func priorityTableViewCell(_ cell: PriorityTableViewCell, didSelect priority: Int)
    @objc optional func priorityTableViewCellDidPressCancelTransport(_ cell: PriorityTableViewCell)
    @objc optional func priorityTableViewCellDidPressTransport(_ cell: PriorityTableViewCell)
    @objc optional func priorityTableViewCellDidSetEditing(_ cell: PriorityTableViewCell)
}

class PriorityTableViewCell: BasePatientTableViewCell, PriorityViewDelegate {
    weak var stackView: UIStackView!
    var stackViewBottomConstraint: NSLayoutConstraint!
    weak var statusButton: UIButton!
    weak var updateButton: FormButton!
    weak var transportButton: FormButton!
    weak var cancelTransportButton: FormButton!
    weak var statusBeforeTransportView: UIView!
    weak var statusBeforeTransportButton: UIButton!
    weak var priorityView: PriorityView!
    var priorityViewBottomConstraint: NSLayoutConstraint!
    weak var delegate: PriorityTableViewCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // swiftlint:disable:next function_body_length
    func commonInit() {
        selectionStyle = .none

        let backgroundView = UIView()
        backgroundView.backgroundColor = .bgBackground
        self.backgroundView = backgroundView

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.spacing = 11
        contentView.addSubview(stackView)
        stackViewBottomConstraint = contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -22),
            stackViewBottomConstraint
        ])
        self.stackView = stackView

        let statusButton = UIButton(type: .custom)
        statusButton.translatesAutoresizingMaskIntoConstraints = false
        statusButton.isUserInteractionEnabled = false
        statusButton.titleLabel?.font = .copySBold
        stackView.addArrangedSubview(statusButton)
        self.statusButton = statusButton

        let buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 7
        stackView.addArrangedSubview(buttonStackView)

        let updateButton = FormButton(size: .xsmall, style: .lowPriority)
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.addTarget(self, action: #selector(updatePressed), for: .touchUpInside)
        updateButton.buttonLabel = "Button.updateStatus".localized
        buttonStackView.addArrangedSubview(updateButton)
        NSLayoutConstraint.activate([
            updateButton.widthAnchor.constraint(equalTo: buttonStackView.widthAnchor)
        ])
        self.updateButton = updateButton

        let transportButton = FormButton(size: .xsmall, style: .lowPriority)
        transportButton.translatesAutoresizingMaskIntoConstraints = false
        transportButton.addTarget(self, action: #selector(transportPressed), for: .touchUpInside)
        transportButton.buttonLabel = "Button.transportPatient".localized
        buttonStackView.addArrangedSubview(transportButton)
        NSLayoutConstraint.activate([
            transportButton.widthAnchor.constraint(equalTo: buttonStackView.widthAnchor)
        ])
        self.transportButton = transportButton

        let cancelTransportButton = FormButton(size: .xsmall, style: .lowPriority)
        cancelTransportButton.translatesAutoresizingMaskIntoConstraints = false
        cancelTransportButton.addTarget(self, action: #selector(cancelTransportPressed), for: .touchUpInside)
        cancelTransportButton.buttonLabel = "Button.cancelTransport".localized
        cancelTransportButton.isHidden = true
        buttonStackView.addArrangedSubview(cancelTransportButton)
        NSLayoutConstraint.activate([
            cancelTransportButton.widthAnchor.constraint(equalTo: buttonStackView.widthAnchor)
        ])
        self.cancelTransportButton = cancelTransportButton

        let statusBeforeTransportView = UIView()
        statusBeforeTransportView.translatesAutoresizingMaskIntoConstraints = false
        statusBeforeTransportView.isHidden = true
        buttonStackView.addArrangedSubview(statusBeforeTransportView)
        NSLayoutConstraint.activate([
            statusBeforeTransportView.heightAnchor.constraint(equalTo: cancelTransportButton.heightAnchor),
            statusBeforeTransportView.widthAnchor.constraint(equalTo: buttonStackView.widthAnchor)
        ])
        self.statusBeforeTransportView = statusBeforeTransportView

        let statusBeforeTransportLabel = UILabel()
        statusBeforeTransportLabel.translatesAutoresizingMaskIntoConstraints = false
        statusBeforeTransportLabel.font = .copyXSRegular
        statusBeforeTransportLabel.textColor = .mainGrey
        statusBeforeTransportLabel.text = "PriorityTableViewCell.statusBeforeTransportLabel".localized
        statusBeforeTransportView.addSubview(statusBeforeTransportLabel)
        NSLayoutConstraint.activate([
            statusBeforeTransportLabel.topAnchor.constraint(equalTo: statusBeforeTransportView.topAnchor),
            statusBeforeTransportLabel.centerXAnchor.constraint(equalTo: statusBeforeTransportView.centerXAnchor)
        ])

        let statusBeforeTransportButton = UIButton()
        statusBeforeTransportButton.translatesAutoresizingMaskIntoConstraints = false
        statusBeforeTransportButton.isUserInteractionEnabled = false
        statusBeforeTransportButton.titleLabel?.font = .copySBold
        statusBeforeTransportButton.alpha = 0.6
        statusBeforeTransportView.addSubview(statusBeforeTransportButton)
        NSLayoutConstraint.activate([
            statusBeforeTransportButton.topAnchor.constraint(equalTo: statusBeforeTransportLabel.bottomAnchor, constant: 4),
            statusBeforeTransportButton.widthAnchor.constraint(equalTo: statusBeforeTransportView.widthAnchor),
            statusBeforeTransportButton.bottomAnchor.constraint(equalTo: statusBeforeTransportView.bottomAnchor)
        ])
        self.statusBeforeTransportButton = statusBeforeTransportButton

        let priorityView = PriorityView()
        priorityView.translatesAutoresizingMaskIntoConstraints = false
        priorityView.isHidden = true
        priorityView.delegate = self
        contentView.addSubview(priorityView)
        priorityViewBottomConstraint = contentView.bottomAnchor.constraint(equalTo: priorityView.bottomAnchor, constant: 10)
        NSLayoutConstraint.activate([
            priorityView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            priorityView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            priorityView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -22)
        ])
        self.priorityView = priorityView
    }

    override func configure(from patient: Patient) {
        priorityView.select(priority: patient.priority.value)

        if let priority = patient.priority.value {
            statusBeforeTransportButton.setTitle("Patient.priority.\(priority)".localized, for: .normal)
            statusBeforeTransportButton.setTitleColor(PRIORITY_LABEL_COLORS[priority], for: .normal)
            statusBeforeTransportButton.setBackgroundImage(UIImage.resizableImage(withColor: PRIORITY_COLORS[priority], cornerRadius: 5),
                                                           for: .normal)
        }
        if let priority = patient.filterPriority.value {
            statusButton.setTitle("Patient.priority.\(priority)".localized, for: .normal)
            statusButton.setTitleColor(PRIORITY_LABEL_COLORS[priority], for: .normal)
            statusButton.setBackgroundImage(UIImage.resizableImage(withColor: PRIORITY_COLORS[priority], cornerRadius: 5), for: .normal)
        }

        if patient.isTransported {
            updateButton.isHidden = true
            transportButton.isHidden = true
            cancelTransportButton.isHidden = false
            statusBeforeTransportView.isHidden = false
        } else {
            updateButton.isHidden = false
            transportButton.isHidden = false
            cancelTransportButton.isHidden = true
            statusBeforeTransportView.isHidden = true
        }

        setPriorityViewVisible(patient.priority.value == nil)
    }

    func setPriorityViewVisible(_ isVisible: Bool) {
        stackViewBottomConstraint.isActive = false
        priorityViewBottomConstraint.isActive = false
        if isVisible {
            stackView.isHidden = true
            priorityView.isHidden = false
            priorityViewBottomConstraint.isActive = true
        } else {
            priorityView.isHidden = true
            stackView.isHidden = false
            stackViewBottomConstraint.isActive = true
        }
    }

    @objc func cancelTransportPressed() {
        delegate?.priorityTableViewCellDidPressCancelTransport?(self)
    }

    @objc func transportPressed() {
        delegate?.priorityTableViewCellDidPressTransport?(self)
    }

    @objc func updatePressed() {
        setPriorityViewVisible(true)
        delegate?.priorityTableViewCellDidSetEditing?(self)
    }

    // MARK: - PriorityViewDelegate

    func priorityView(_ view: PriorityView, didSelect priority: Int) {
        delegate?.priorityTableViewCell?(self, didSelect: priority)
        setPriorityViewVisible(false)
        delegate?.priorityTableViewCellDidSetEditing?(self)
    }
}
