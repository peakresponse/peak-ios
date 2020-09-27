//
//  PatientsCollectionViewCell.swift
//  Triage
//
//  Created by Francis Li on 9/14/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

class PatientsCollectionViewCell: UICollectionViewCell {
    var patientView: PatientView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        patientView = PatientView()
        patientView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(patientView)
        NSLayoutConstraint.activate([
            patientView.topAnchor.constraint(equalTo: contentView.topAnchor),
            patientView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            patientView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: patientView.bottomAnchor)
        ])
    }

    func configure(from patient: Patient) {
        patientView.configure(from: patient)
    }
}
