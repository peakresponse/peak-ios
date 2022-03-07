//
//  Ringdown.swift
//  Triage
//
//  Created by Francis Li on 3/6/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import RealmSwift

enum RingdownEmergencyServiceResponseType: String {
    case code2 = "CODE 2"
    case code3 = "CODE 3"
}

class Ringdown: Object {
    @Persisted(primaryKey: true) var id = UUID().uuidString.lowercased()
    @Persisted var emergencyServiceResponseType: String?
    @Persisted var stableIndicator: Bool?
}
