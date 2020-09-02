//
//  AppTabBarController.swift
//  Triage
//
//  Created by Francis Li on 11/3/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class AppTabBarController: TabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        /// hit the server to check current log-in status
        let task = ApiClient.shared.me { [weak self] (record, error) in
            if let error = error {
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
        }
        task.resume();
    }
}
