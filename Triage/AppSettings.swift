//
//  AppSettings.swift
//  Triage
//
//  Created by Francis Li on 4/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation

class AppSettings {
    private static let defaults = UserDefaults.standard
    
    static var audioInputPortUID: String? {
        get { return defaults.string(forKey: "audioInputPortUID") }
        set { defaults.set(newValue, forKey: "audioInputPortUID") }
    }
}
