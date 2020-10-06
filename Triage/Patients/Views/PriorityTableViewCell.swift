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
    @objc optional func priorityTableViewCellDidSetEditing(_ cell: PriorityTableViewCell)
}

class PriorityTableViewCell: BasePatientTableViewCell, PriorityViewDelegate {
    var isEditingOverride = false
    weak var stackView: UIStackView!
    var stackViewBottomConstraint: NSLayoutConstraint!
    weak var statusButton: UIButton!
    weak var updateButton: FormButton!
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
        stackView.alignment = .leading
        stackView.axis = .horizontal
        stackView.spacing = 7
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
        NSLayoutConstraint.activate([
            statusButton.heightAnchor.constraint(equalToConstant: 46)
        ])
        self.statusButton = statusButton

        let updateButtonView = UIView()
        updateButtonView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(updateButtonView)
        NSLayoutConstraint.activate([
            updateButtonView.widthAnchor.constraint(equalTo: statusButton.widthAnchor, multiplier: 2)
        ])

        let updateButton = FormButton(size: .xsmall, style: .lowPriority)
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.addTarget(self, action: #selector(updatePressed), for: .touchUpInside)
        updateButton.buttonLabel = "Button.updateStatus".localized
        updateButtonView.addSubview(updateButton)
        NSLayoutConstraint.activate([
            updateButton.topAnchor.constraint(equalTo: updateButtonView.topAnchor),
            updateButton.leftAnchor.constraint(equalTo: updateButtonView.leftAnchor),
            updateButtonView.bottomAnchor.constraint(equalTo: updateButton.bottomAnchor)
        ])
        self.updateButton = updateButton

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
            statusButton.setTitle("Patient.priority.\(priority)".localized, for: .normal)
            statusButton.setTitleColor(PRIORITY_LABEL_COLORS[priority], for: .normal)
            statusButton.setBackgroundImage(UIImage.resizableImage(withColor: PRIORITY_COLORS[priority], cornerRadius: 5), for: .normal)
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        stackViewBottomConstraint.isActive = false
        priorityViewBottomConstraint.isActive = false
        if editing || isEditingOverride {
            stackView.isHidden = true
            priorityView.isHidden = false
            priorityViewBottomConstraint.isActive = true
        } else {
            priorityView.isHidden = true
            stackView.isHidden = false
            stackViewBottomConstraint.isActive = true
        }
    }

    @objc func updatePressed() {
        isEditingOverride = true
        setEditing(true, animated: false)
        delegate?.priorityTableViewCellDidSetEditing?(self)
    }

    // MARK: - PriorityViewDelegate

    func priorityView(_ view: PriorityView, didSelect priority: Int) {
        let isEditingOverride = self.isEditingOverride
        self.isEditingOverride = false
        delegate?.priorityTableViewCell?(self, didSelect: priority)
        if isEditingOverride {
            setEditing(false, animated: false)
            delegate?.priorityTableViewCellDidSetEditing?(self)
        }
    }
}
