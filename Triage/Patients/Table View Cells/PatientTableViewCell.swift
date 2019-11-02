//
//  PatientTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class PatientTableViewCell: UITableViewCell {
    var editable: Bool {
        get { return false }
        set { }
    }

    func configure(from patient: Patient) {
    }
}
