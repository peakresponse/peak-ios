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
    var isLast = false {
        didSet { updateBackgroundStyle() }
    }
    
    func configure(from patient: Patient) {
    }

    func updateBackgroundStyle() {
        if let self = self as? PatientTableViewCellBackground {
            if isLast {
                self.customBackgroundView.layer.cornerRadius = 5
                self.customBackgroundView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                self.customBackgroundView.layer.cornerRadius = 0
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if let self = self as? PatientTableViewCellBackground {
            self.customBackgroundView.backgroundColor = (highlighted && selectionStyle != .none) ? .bottomBlueGray : .white
        }
    }
}
