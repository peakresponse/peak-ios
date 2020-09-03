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
    override var inputAccessoryView: UIView? {
        get { return nil }
        set { }
    }
    
    func configure(from patient: Patient) {
    }
}
