//
//  PortraitTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class PortraitTableViewCell: PatientTableViewCell {
    @IBOutlet weak var patientView: PatientView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func configure(from patient: Patient) {
        selectionStyle = .none
        patientView.configure(from: patient)
    }
}
