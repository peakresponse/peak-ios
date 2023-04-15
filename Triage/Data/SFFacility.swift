//
//  SFFacility.swift
//  Triage
//
//  Created by Francis Li on 4/14/23.
//  Copyright © 2023 Francis Li. All rights reserved.
//

import Foundation
import PRKit

enum SFFacility: String, StringCaseIterable {
    case sfGeneral = "20386"
    case missionBernal = "20050"
    case cpmcDavies = "20048"
    case cpmcVanNess = "62636"
    case stFrancis = "20447"
    case chineseHospital = "20065"
    case kaiserSF = "20199"
    case stMarys = "20462"
    case ucsfParnassus = "20504"
    case vaMedCenter = "20540"

    var description: String {
      return "SFFacility.\(rawValue)".localized
    }
}
