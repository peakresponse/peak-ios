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

    static var userId: String? {
        get { return defaults.string(forKey: "userId") }
        set { defaults.set(newValue, forKey: "userId") }
    }

    static var agencyId: String? {
        get { return defaults.string(forKey: "agencyId") }
        set { defaults.set(newValue, forKey: "agencyId") }
    }

    static var sceneId: String? {
        get { return defaults.string(forKey: "sceneId") }
        set { defaults.set(newValue, forKey: "sceneId") }
    }

    static var subdomain: String? {
        get { return defaults.string(forKey: "subdomain") }
        set { defaults.set(newValue, forKey: "subdomain") }
    }

    static func login(userId: String, agencyId: String, sceneId: String?) {
        AppSettings.userId = userId
        AppSettings.agencyId = agencyId
        AppSettings.sceneId = sceneId
    }

    static func logout() {
        AppSettings.userId = nil
        AppSettings.agencyId = nil
        AppSettings.sceneId = nil
        AppSettings.subdomain = nil
    }
}
