//
//  PatientView.swift
//  Triage
//
//  Created by Francis Li on 9/26/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class PatientView: UIView {
    weak var containerView: UIView!
    weak var priorityView: UIView!
    weak var priorityLabel: UILabel!
    weak var portraitView: PortraitView!
    weak var tagLabel: UILabel!
    weak var updatedLabel: UILabel!
    weak var genderLabel: UILabel!
    weak var ageLabel: UILabel!
    weak var complaintLabel: UILabel!

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
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 3
        containerView.addShadow(withOffset: CGSize(width: 2, height: 2), radius: 4, color: .black, opacity: 0.1)
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leftAnchor.constraint(equalTo: leftAnchor),
            containerView.rightAnchor.constraint(equalTo: rightAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 86),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        self.containerView = containerView

        let priorityView = UIView()
        priorityView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(priorityView)
        priorityView.layer.cornerRadius = 3
        priorityView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        NSLayoutConstraint.activate([
            priorityView.topAnchor.constraint(equalTo: containerView.topAnchor),
            priorityView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            priorityView.rightAnchor.constraint(equalTo: containerView.rightAnchor)
        ])
        self.priorityView = priorityView

        let portraitView = PortraitView()
        portraitView.translatesAutoresizingMaskIntoConstraints = false
        priorityView.addSubview(portraitView)
        NSLayoutConstraint.activate([
            portraitView.topAnchor.constraint(equalTo: priorityView.topAnchor, constant: 4),
            portraitView.leftAnchor.constraint(equalTo: priorityView.leftAnchor, constant: 6),
            portraitView.widthAnchor.constraint(equalToConstant: 36),
            portraitView.heightAnchor.constraint(equalToConstant: 36),
            priorityView.bottomAnchor.constraint(equalTo: portraitView.bottomAnchor, constant: 4)
        ])
        self.portraitView = portraitView

        let tagLabel = UILabel()
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.font = .copyMBold
        tagLabel.text = String(format: "Patient.pin".localized, "")
        tagLabel.textColor = .mainGrey
        priorityView.addSubview(tagLabel)
        NSLayoutConstraint.activate([
            tagLabel.centerYAnchor.constraint(equalTo: priorityView.centerYAnchor),
            tagLabel.leftAnchor.constraint(equalTo: portraitView.rightAnchor, constant: 10)
        ])

        let tagValueLabel = UILabel()
        tagValueLabel.translatesAutoresizingMaskIntoConstraints = false
        tagValueLabel.font = .copyMRegular
        tagValueLabel.textColor = .mainGrey
        priorityView.addSubview(tagValueLabel)
        NSLayoutConstraint.activate([
            tagValueLabel.centerYAnchor.constraint(equalTo: priorityView.centerYAnchor),
            tagValueLabel.leftAnchor.constraint(equalTo: tagLabel.rightAnchor)
        ])
        self.tagLabel = tagValueLabel

        let priorityLabel = UILabel()
        priorityLabel.translatesAutoresizingMaskIntoConstraints = false
        priorityLabel.font = .copyXSBold
        priorityLabel.textColor = .mainGrey
        priorityView.addSubview(priorityLabel)
        NSLayoutConstraint.activate([
            priorityLabel.topAnchor.constraint(equalTo: priorityView.topAnchor, constant: 4),
            priorityLabel.rightAnchor.constraint(equalTo: priorityView.rightAnchor, constant: -6)
        ])
        self.priorityLabel = priorityLabel

        let updatedLabel = UILabel()
        updatedLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedLabel.font = .copyXSRegular
        updatedLabel.textColor = .mainGrey
        priorityView.addSubview(updatedLabel)
        NSLayoutConstraint.activate([
            updatedLabel.topAnchor.constraint(equalTo: priorityLabel.bottomAnchor, constant: 2),
            updatedLabel.rightAnchor.constraint(equalTo: priorityView.rightAnchor, constant: -6)
        ])
        self.updatedLabel = updatedLabel

        let detailsView = UIView()
        detailsView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(detailsView)
        NSLayoutConstraint.activate([
            detailsView.topAnchor.constraint(equalTo: priorityView.bottomAnchor),
            detailsView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            detailsView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            detailsView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        let genderLabel = UILabel()
        genderLabel.translatesAutoresizingMaskIntoConstraints = false
        genderLabel.font = .copySBold
        genderLabel.text = "\("Patient.gender".localized): "
        genderLabel.textColor = .mainGrey
        detailsView.addSubview(genderLabel)
        NSLayoutConstraint.activate([
            genderLabel.centerYAnchor.constraint(equalTo: detailsView.centerYAnchor),
            genderLabel.leftAnchor.constraint(equalTo: detailsView.leftAnchor, constant: 6)
        ])

        let genderValueLabel = UILabel()
        genderValueLabel.translatesAutoresizingMaskIntoConstraints = false
        genderValueLabel.font = .copySRegular
        genderValueLabel.textColor = .mainGrey
        detailsView.addSubview(genderValueLabel)
        NSLayoutConstraint.activate([
            genderValueLabel.centerYAnchor.constraint(equalTo: detailsView.centerYAnchor),
            genderValueLabel.leftAnchor.constraint(equalTo: genderLabel.rightAnchor)
        ])
        self.genderLabel = genderValueLabel

        let ageLabel = UILabel()
        ageLabel.translatesAutoresizingMaskIntoConstraints = false
        ageLabel.font = .copySBold
        ageLabel.text = "\("Patient.age".localized): "
        ageLabel.textColor = .mainGrey
        detailsView.addSubview(ageLabel)
        NSLayoutConstraint.activate([
            ageLabel.centerYAnchor.constraint(equalTo: detailsView.centerYAnchor),
            ageLabel.leftAnchor.constraint(equalTo: detailsView.leftAnchor, constant: 94)
        ])

        let ageValueLabel = UILabel()
        ageValueLabel.translatesAutoresizingMaskIntoConstraints = false
        ageValueLabel.font = .copySRegular
        ageValueLabel.textColor = .mainGrey
        detailsView.addSubview(ageValueLabel)
        NSLayoutConstraint.activate([
            ageValueLabel.centerYAnchor.constraint(equalTo: detailsView.centerYAnchor),
            ageValueLabel.leftAnchor.constraint(equalTo: ageLabel.rightAnchor)
        ])
        self.ageLabel = ageValueLabel

        let complaintLabel = UILabel()
        complaintLabel.translatesAutoresizingMaskIntoConstraints = false
        complaintLabel.font = .copySBold
        complaintLabel.text = "\("Patient.complaint.abbr".localized): "
        complaintLabel.textColor = .mainGrey
        containerView.addSubview(complaintLabel)
        NSLayoutConstraint.activate([
            complaintLabel.centerYAnchor.constraint(equalTo: detailsView.centerYAnchor),
            complaintLabel.leftAnchor.constraint(equalTo: detailsView.leftAnchor, constant: 170)
        ])

        let complaintValueLabel = UILabel()
        complaintValueLabel.translatesAutoresizingMaskIntoConstraints = false
        complaintValueLabel.font = .copySRegular
        complaintValueLabel.textColor = .mainGrey
        containerView.addSubview(complaintValueLabel)
        NSLayoutConstraint.activate([
            complaintValueLabel.centerYAnchor.constraint(equalTo: detailsView.centerYAnchor),
            complaintValueLabel.leftAnchor.constraint(equalTo: complaintLabel.rightAnchor),
            complaintValueLabel.rightAnchor.constraint(equalTo: detailsView.rightAnchor, constant: -6)
        ])
        self.complaintLabel = complaintValueLabel
    }

    func configure(from patient: Patient) {
        priorityView.backgroundColor = PRIORITY_COLORS_LIGHTENED[patient.priority.value ?? Priority.unknown.rawValue]
        priorityLabel.text = Priority(rawValue: patient.priority.value ?? Priority.unknown.rawValue)?.description ?? ""
        portraitView.configure(from: patient)
        tagLabel.text = patient.pin
        updatedLabel.text = String(format: "Patient.updatedAt".localized, patient.updatedAtRelativeString)
        genderLabel.text = PatientGender(rawValue: patient.gender ?? "")?.abbrDescription ?? ""
        ageLabel.text = patient.ageString
        complaintLabel.text = patient.complaint
    }
}
