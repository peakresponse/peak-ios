//
//  PatientTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 9/26/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class PatientTableViewCell: BasePatientTableViewCell {
    weak var patientView: PatientView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .bgBackground
        self.backgroundView = backgroundView

        let patientView = PatientView()
        patientView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(patientView)
        NSLayoutConstraint.activate([
            patientView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            patientView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            patientView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -22),
            contentView.bottomAnchor.constraint(equalTo: patientView.bottomAnchor, constant: 7)
        ])
        self.patientView = patientView
    }

    override func configure(from patient: Patient) {
        patientView.configure(from: patient)
    }
}
