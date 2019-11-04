//
//  AppTabBarController.swift
//  Triage
//
//  Created by Francis Li on 11/3/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class AppTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let task = ApiClient.shared.me { [weak self] (record, error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    if let error = error as? ApiClientError, error == .unauthorized {
                        self?.presentLogin()
                    } else {
                        self?.presentAlert(error: error)
                    }
                }
            }
        }
        task.resume();
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
