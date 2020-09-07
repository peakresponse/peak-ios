//
//  PatientTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

protocol PatientTableViewCellBackground {
    var customBackgroundView: UIView! { get set }
}

class PatientTableViewCell: UITableViewCell {    
    func configure(from patient: Patient) {
    }
}
