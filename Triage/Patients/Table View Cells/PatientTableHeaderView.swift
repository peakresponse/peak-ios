//
//  PortraitTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

@objc protocol PatientTableHeaderViewDelegate: PriorityViewDelegate {
    @objc optional func patientTableHeaderView(_ view: PatientTableHeaderView, didPressTransportButton button: FormButton)
    @objc optional func patientTableHeaderView(_ view: PatientTableHeaderView, didPressStatusButton button: FormButton)
}

class PatientTableHeaderView: UIView, PriorityViewDelegate {
    let patientView = PatientView()
    let nameLabel = UILabel()
    let updatedLabel = UILabel()
    let priorityLabel = UILabel()
    let stackView = UIStackView()
    let transportButton = FormButton(size: .xsmall, style: .lowPriority)
    let statusButton = FormButton(size: .xsmall, style: .lowPriority)
    var priority: Int?
    var priorityView: PriorityView?
    var bottomConstraint: NSLayoutConstraint!

    var isEditing: Bool {
        get { return patientView.isEditing }
        set { patientView.isEditing = newValue }
    }
    
    @IBOutlet weak var delegate: PatientTableHeaderViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        patientView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(patientView)
        NSLayoutConstraint.activate([
            patientView.widthAnchor.constraint(equalToConstant: 100),
            patientView.heightAnchor.constraint(equalToConstant: 100),
            patientView.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            patientView.rightAnchor.constraint(equalTo: rightAnchor, constant: -22)
        ])

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .copyLBold
        nameLabel.textColor = .mainGrey
        addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 30),
            nameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 22)
        ])
        
        var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copySBold
        label.text = "Last Updated:".localized
        label.textColor = .mainGrey
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 18),
            label.leftAnchor.constraint(equalTo: nameLabel.leftAnchor)
        ])

        updatedLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedLabel.font = .copySRegular
        updatedLabel.textColor = .mainGrey
        addSubview(updatedLabel)
        NSLayoutConstraint.activate([
            updatedLabel.firstBaselineAnchor.constraint(equalTo: label.firstBaselineAnchor),
            updatedLabel.leftAnchor.constraint(equalTo: label.rightAnchor)
        ])

        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copySBold
        label.text = "Status:".localized
        label.textColor = .mainGrey
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: updatedLabel.bottomAnchor, constant: 4),
            label.leftAnchor.constraint(equalTo: nameLabel.leftAnchor)
        ])
        
        priorityLabel.translatesAutoresizingMaskIntoConstraints = false
        priorityLabel.font = .copySRegular
        priorityLabel.textColor = .mainGrey
        addSubview(priorityLabel)
        NSLayoutConstraint.activate([
            priorityLabel.firstBaselineAnchor.constraint(equalTo: label.firstBaselineAnchor),
            priorityLabel.leftAnchor.constraint(equalTo: label.rightAnchor)
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        addSubview(stackView)
        bottomConstraint = bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: patientView.bottomAnchor, constant: 16),
            stackView.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: patientView.rightAnchor),
            bottomConstraint
        ])
        
        transportButton.buttonLabel = "Transport".localized
        transportButton.addTarget(self, action: #selector(transportPressed), for: .touchUpInside)
        stackView.addArrangedSubview(transportButton)
        
        statusButton.buttonLabel = "Update Status".localized
        statusButton.addTarget(self, action: #selector(statusPressed), for: .touchUpInside)
        stackView.addArrangedSubview(statusButton)
    }

    func configure(from patient: Patient) {
        priority = patient.priority.value
        backgroundColor = PRIORITY_COLORS_LIGHTENED[priority ?? 5]
        patientView.configure(from: patient)
        
        nameLabel.text = patient.fullName
        updatedLabel.text = patient.updatedAtRelativeString
        priorityLabel.text = "Patient.priority.\(priority ?? 5)".localized
    }

    @objc func transportPressed() {
        delegate?.patientTableHeaderView?(self, didPressTransportButton: transportButton)
    }
    
    @objc func statusPressed() {
        let priorityView = PriorityView()
        priorityView.delegate = self
        priorityView.selectedPriority = priority
        priorityView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(priorityView)
        /// change bottom constraint
        bottomConstraint.isActive = false
        bottomConstraint = bottomAnchor.constraint(equalTo: priorityView.bottomAnchor)
        NSLayoutConstraint.activate([
            priorityView.topAnchor.constraint(equalTo: stackView.topAnchor),
            priorityView.leftAnchor.constraint(equalTo: leftAnchor),
            priorityView.rightAnchor.constraint(equalTo: rightAnchor),
            bottomConstraint
        ])        
        self.priorityView = priorityView
        delegate?.patientTableHeaderView?(self, didPressStatusButton: statusButton)
    }
    
    // MARK: - PriorityViewDelegate

    func priorityViewDidDismiss(_ view: PriorityView) {
        /// remove from view
        bottomConstraint.isActive = false
        view.removeFromSuperview()
        priorityView = nil
        bottomConstraint = bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12)
        bottomConstraint.isActive = true
        delegate?.priorityViewDidDismiss?(view)
    }
    
    func priorityView(_ view: PriorityView, didSelect priority: Int) {
        delegate?.priorityView?(view, didSelect: priority)
        priorityViewDidDismiss(view)
    }
}
