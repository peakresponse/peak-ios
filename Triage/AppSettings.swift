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

    static var assignmentId: String? {
        get { return defaults.string(forKey: "assignmentId") }
        set { defaults.set(newValue, forKey: "assignmentId") }
    }

    static var lastPingDate: Date? {
        get { return defaults.object(forKey: "lastPingDate") as? Date }
        set { defaults.set(newValue, forKey: "lastPingDate") }
    }

    static var sceneId: String? {
        get { return defaults.string(forKey: "sceneId") }
        set { defaults.set(newValue, forKey: "sceneId") }
    }

    static var lastScenePingDate: Date? {
        get { return defaults.object(forKey: "lastScenePingDate") as? Date }
        set { defaults.set(newValue, forKey: "lastScenePingDate") }
    }

    static var subdomain: String? {
        get { return defaults.string(forKey: "subdomain") }
        set { defaults.set(newValue, forKey: "subdomain") }
    }

    static var awsCredentials: [String: String]? {
        get { return defaults.dictionary(forKey: "awsCredentials") as? [String: String] }
        set { defaults.set(newValue, forKey: "awsCredentials") }
    }

    static func login(userId: String, agencyId: String, assignmentId: String?, sceneId: String?) {
        AppSettings.userId = userId
        AppSettings.agencyId = agencyId
        AppSettings.assignmentId = assignmentId
        AppSettings.sceneId = sceneId
    }

    static func logout() {
        AppSettings.userId = nil
        AppSettings.agencyId = nil
        AppSettings.assignmentId = nil
        AppSettings.sceneId = nil
        AppSettings.subdomain = nil
    }
}
