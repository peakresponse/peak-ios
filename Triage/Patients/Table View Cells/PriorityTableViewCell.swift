//
//  PriorityTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class PriorityTableViewCell: PatientTableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func configure(from patient: Patient) {
        contentView.backgroundColor = PRIORITY_COLORS[patient.priority.value ?? 5]
        textLabel?.text = NSLocalizedString("Patient.priority.\(patient.priority.value ?? 5)", comment: "")
        textLabel?.textColor = PRIORITY_LABEL_COLORS[patient.priority.value ?? 5]
    }
}
