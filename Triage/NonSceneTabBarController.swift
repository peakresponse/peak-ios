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
        // temporarily hide other options
        for (i, view) in customTabBar.stackView.arrangedSubviews.enumerated() where i != 2 {
            view.alpha = 0
            view.isUserInteractionEnabled = false
        }
        // hit the server to check current log-in status
        AppRealm.me { (user, agency, scene, error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    var vc = self?.selectedViewController
                    if let navVC = vc as? UINavigationController {
                        vc = navVC.topViewController
                    }
                    if let error = error as? ApiClientError, error == .unauthorized || error == .forbidden || error == .notFound {
                        vc?.logout()
                    } else {
                        vc?.presentAlert(error: error)
                    }
                }
            } else {
                AppSettings.userId = user?.id
                AppSettings.agencyId = agency?.id
                if let scene = scene {
                    let sceneId = scene.id
                    DispatchQueue.main.async {
                        AppDelegate.enterScene(id: sceneId)
                    }
                } else {
                    AppSettings.sceneId = nil
                    AppRealm.connect()
                }
            }
        }
    }
}
