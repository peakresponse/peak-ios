//
//  PredictionStatus.swift
//  Triage
//
//  Created by Francis Li on 10/25/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation

enum PredictionStatus: String {
    case none
    case unconfirmed = "UNCONFIRMED"
    case confirmed = "CONFIRMED"
    case corrected = "CORRECTED"
}
