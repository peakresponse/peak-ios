//
//  CityKeyboard.swift
//  Triage
//
//  Created by Francis Li on 10/31/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import CoreLocation
import Foundation
import PRKit

class CityKeyboard: SearchKeyboard {
    var currentLocation: CLLocationCoordinate2D? {
        didSet {
            if let source = source as? CityKeyboardSource {
                source.currentLocation = currentLocation
            }
        }
    }
    var stateId: String? {
        didSet {
            if let source = source as? CityKeyboardSource {
                source.stateId = stateId
            }
        }
    }

    init() {
        super.init(source: CityKeyboardSource(), isMultiSelect: false)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
