//
//  PatientView.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class PatientView: UIView {
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        loadNib()
    }

    func configure(from patient: Patient) {
        if let priority = patient.priority.value {
            imageView.layer.borderColor = PRIORITY_COLORS[priority].cgColor
            imageView.layer.borderWidth = 4
        }
        let initials = "\(patient.firstName?.prefix(1) ?? "")\(patient.lastName?.prefix(1) ?? "")"
        initialsLabel.text = initials
    }
}
