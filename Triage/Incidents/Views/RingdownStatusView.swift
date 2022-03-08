//
//  RingdownStatusView.swift
//  Triage
//
//  Created by Francis Li on 3/8/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import PRKit
import UIKit

class RingdownStatusView: UIView {
    weak var hospitalNameLabel: UILabel!
    weak var ringdownStatusLabel: UILabel!
    weak var ringdownStatusChip: Chip!
    weak var arrivalLabel: UILabel!
    weak var arrivalTimeLabel: UILabel!
    weak var redirectButton: PRKit.Button!
    weak var cancelButton: PRKit.Button!
}
