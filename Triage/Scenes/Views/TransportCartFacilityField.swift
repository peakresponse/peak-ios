//
//  TransportCartFacilityField.swift
//  Triage
//
//  Created by Francis Li on 3/12/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

class TransportCartFacilityField: CellField {
    override func commonInit() {
        super.commonInit()
        isLabelHidden = true
        disclosureIndicatorView.widthAnchor.constraint(equalToConstant: 0).isActive = true
    }

    func configure(from facility: Facility?) {
        text = facility?.name // displayName
    }
}
