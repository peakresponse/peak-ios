//
//  NonSceneTabBarController.swift
//  Triage
//
//  Created by Francis Li on 11/3/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class NonSceneTabBarController: TabBarController {
    deinit {
        AppRealm.disconnect()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// hit the server to check current log-in status
        AppRealm.me { (user, agency, scene, error) in
            if let error = error {
                AppSettings.userId = nil
                AppSettings.agencyId = nil
                DispatchQueue.main.async { [weak self] in
                    var vc = self?.selectedViewController
                    if let navVC = vc as? UINavigationController {
                        vc = navVC.topViewController
                    }
                    if let error = error as? ApiClientError, error == .unauthorized || error == .forbidden {
                        vc?.presentLogin()
                    } else {
                        vc?.presentAlert(error: error)
                    }
                }
            }
            AppSettings.userId = user?.id
            AppSettings.agencyId = agency?.id
            if let scene = scene {
                let sceneId = scene.id
                DispatchQueue.main.async {
                    AppDelegate.enterScene(id: sceneId)
                }
            } else {
                AppRealm.connect()
            }
        }
    }
}
