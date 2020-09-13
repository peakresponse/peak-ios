//
//  SceneTabBarController.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class SceneTabBarController: TabBarController {
    deinit {
        AppRealm.disconnectScene()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let sceneId = AppSettings.sceneId {
            AppRealm.connect(sceneId: sceneId)
        }
    }
}
