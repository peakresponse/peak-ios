//
//  AppDelegate.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import GoogleMaps
import ArkanaKeys
import LLMKitAWSBedrock
import RollbarNotifier
import UIKit
internal import ICD10Kit
internal import RxNormKit
internal import SNOMEDKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    static func enterScene(id: String) {
        AppSettings.sceneId = id
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ActiveScene")
        for window in UIApplication.shared.windows where window.isKeyWindow {
            window.rootViewController = vc
            window.makeKeyAndVisible()
            break
        }
    }

    static func leaveScene() -> UIViewController {
        AppSettings.sceneId = nil
        var vc: UIViewController!
        if let eventId = AppSettings.eventId {
            let incidentsVC = IncidentsViewController()
            incidentsVC.eventId = eventId
            vc = incidentsVC
        } else if let agencyId = AppSettings.agencyId, let agency = AppRealm.open().object(ofType: Agency.self, forPrimaryKey: agencyId), agency.isEventsOnly ?? false {
            vc = EventsViewController()
        } else {
            vc = IncidentsViewController()
        }
        for window in UIApplication.shared.windows where window.isKeyWindow {
            window.rootViewController = vc
            window.makeKeyAndVisible()
            break
        }
        return vc
    }

    static func enterEvents() {
        let vc = EventsViewController()
        for window in UIApplication.shared.windows where window.isKeyWindow {
            window.rootViewController = vc
            break
        }
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AWSBedrockBot.register()
        // ensure CallHelper is initialized ASAP after application startup
        _ = CallHelper.shared

        let keys = ArkanaKeys.Global()

        let rollbarConfig = RollbarConfig.mutableConfig(withAccessToken: keys.rollbarPostClientItemAccessToken)
        rollbarConfig.destination.environment = keys.rollbarEnvironment
        rollbarConfig.developerOptions.suppressSdkInfoLogging = true
        Rollbar.initWithConfiguration(rollbarConfig)

        GMSServices.provideAPIKey(keys.googleMapsSdkApiKey)

        CMRealm.configure(url: Bundle.main.url(forResource: "ICD10CM", withExtension: "realm"), isReadOnly: true)
        RxNRealm.configure(url: Bundle.main.url(forResource: "RxNorm", withExtension: "realm"), isReadOnly: true)
        SCTRealm.configure(url: Bundle.main.url(forResource: "SNOMED", withExtension: "realm"), isReadOnly: true)

        UIBarButtonItem.appearance().setTitleTextAttributes([
            .font: UIFont.copySBold,
            .foregroundColor: UIColor.mainGrey
        ], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([
            .font: UIFont.copySBold,
            .foregroundColor: UIColor.mainGrey
        ], for: .highlighted)
        UIBarButtonItem.appearance().setTitleTextAttributes([
            .font: UIFont.copySBold,
            .foregroundColor: UIColor.lowPriorityGrey
        ], for: .disabled)

        UILabel.appearance(whenContainedInInstancesOf: [UISegmentedControl.self]).numberOfLines = 0

        UINavigationBar.appearance().barTintColor = .white
        UINavigationBar.appearance().tintColor = .mainGrey

        UITabBar.appearance().barTintColor = .white

        UIToolbar.appearance().backgroundColor = .bgBackground

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
