//
//  InterstitialViewController.swift
//  Triage
//
//  Created by Francis Li on 4/5/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit

class InterstitialViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // hit the server to check current log-in status
        AppRealm.me { (user, agency, scene, error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if let error = error as? ApiClientError, error == .unauthorized || error == .forbidden || error == .notFound {
                        self.logout()
                    } else {
                        self.presentAlert(error: error)
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
                    DispatchQueue.main.async {
                        AppDelegate.leaveScene()
                    }
                }
            }
        }
    }
}
