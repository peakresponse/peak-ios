//
//  Ringdown.swift
//  Triage
//
//  Created by Francis Li on 3/6/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import RealmSwift

class Ringdown: Object {
    @Persisted(primaryKey: true) var id = UUID().uuidString.lowercased()

}
