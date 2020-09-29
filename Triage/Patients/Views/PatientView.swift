//
//  PatientView.swift
//  Triage
//
//  Created by Francis Li on 9/26/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class PatientView: UIView {
    let containerView = UIView()
    let priorityView = UIView()
    let priorityLabel = UILabel()
    let portraitView = PortraitView()
    let nameLabel = UILabel()
    let updatedLabel = UILabel()
    let genderLabel = UILabel()
    let ageLabel = UILabel()
    let complaintLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 3
        containerView.addShadow(withOffset: CGSize(width: 2, height: 2), radius: 4, color: .black, opacity: 0.1)
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leftAnchor.constraint(equalTo: leftAnchor),
            containerView.rightAnchor.constraint(equalTo: rightAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 70),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        priorityView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(priorityView)
        priorityView.layer.cornerRadius = 3
        priorityView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        NSLayoutConstraint.activate([
            priorityView.topAnchor.constraint(equalTo: containerView.topAnchor),
            priorityView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            priorityView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            priorityView.heightAnchor.constraint(equalToConstant: 16)
        ])

        priorityLabel.translatesAutoresizingMaskIntoConstraints = false
        priorityLabel.font = .copyXSBold
        priorityLabel.textColor = .mainGrey
        containerView.addSubview(priorityLabel)
        NSLayoutConstraint.activate([
            priorityLabel.centerYAnchor.constraint(equalTo: priorityView.centerYAnchor),
            priorityLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -6)
        ])

        portraitView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(portraitView)
        NSLayoutConstraint.activate([
            portraitView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            portraitView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 6),
            portraitView.widthAnchor.constraint(equalToConstant: 36),
            portraitView.heightAnchor.constraint(equalToConstant: 36)
        ])

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .copyMBold
        nameLabel.textColor = .mainGrey
        containerView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: priorityView.bottomAnchor, constant: 2),
            nameLabel.leftAnchor.constraint(equalTo: portraitView.rightAnchor, constant: 10)
        ])

        updatedLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedLabel.font = .copyXSRegular
        updatedLabel.textColor = .mainGrey
        containerView.addSubview(updatedLabel)
        NSLayoutConstraint.activate([
            updatedLabel.topAnchor.constraint(equalTo: priorityView.bottomAnchor, constant: 6),
            updatedLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -6)
        ])

        genderLabel.translatesAutoresizingMaskIntoConstraints = false
        genderLabel.font = .copySRegular
        genderLabel.textColor = .mainGrey
        containerView.addSubview(genderLabel)
        NSLayoutConstraint.activate([
            genderLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            genderLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor)
        ])

        ageLabel.translatesAutoresizingMaskIntoConstraints = false
        ageLabel.font = .copySRegular
        ageLabel.textColor = .mainGrey
        containerView.addSubview(ageLabel)
        NSLayoutConstraint.activate([
            ageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            ageLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor, constant: 60)
        ])

        complaintLabel.translatesAutoresizingMaskIntoConstraints = false
        complaintLabel.font = .copySRegular
        complaintLabel.textColor = .mainGrey
        containerView.addSubview(complaintLabel)
        NSLayoutConstraint.activate([
            complaintLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            complaintLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor, constant: 120)
        ])
    }

    func configure(from patient: Patient) {
        priorityView.backgroundColor = PRIORITY_COLORS_LIGHTENED[patient.priority.value ?? Priority.unknown.rawValue]
        priorityLabel.text = Priority(rawValue: patient.priority.value ?? Priority.unknown.rawValue)?.description ?? ""
        portraitView.configure(from: patient)
        nameLabel.text = patient.fullName
        updatedLabel.text = patient.updatedAtRelativeString
        ageLabel.text = patient.ageString
    }
}
