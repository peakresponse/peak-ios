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
        AppRealm.connect()
    }
}
