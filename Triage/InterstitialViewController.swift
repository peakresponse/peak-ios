//
//  InterstitialViewController.swift
//  Triage
//
//  Created by Francis Li on 4/5/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit

class InterstitialViewController: UIViewController {
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var retryButton: FormButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        checkLoginStatus()
    }

    @IBAction func retryPressed(_ sender: Any) {
        checkLoginStatus()
        retryButton.isHidden = true
    }

    func checkLoginStatus() {
        // hit the server to check current log-in status
        AppRealm.me { (user, agency, assignment, vehicle, scene, awsCredentials, error) in
            // if an explicit server error, log out to force re-login
            if let error = error as? ApiClientError, error == .unauthorized || error == .forbidden || error == .notFound {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.logout()
                }
                return
            }
            if let user = user, let agency = agency {
                // update agency forms in the background
                AppRealm.getForms()
                // update code lists in the background
                AppRealm.getLists { (_) in
                    // noop
                }
                AppSettings.awsCredentials = awsCredentials
                AppSettings.login(userId: user.id, regionId: agency.regionId, agencyId: agency.id, assignmentId: assignment?.id, vehicleId: vehicle?.id, sceneId: scene?.id)
                if let sceneId = scene?.id {
                    DispatchQueue.main.async {
                        AppDelegate.enterScene(id: sceneId)
                    }
                } else {
                    DispatchQueue.main.async {
                        _ = AppDelegate.leaveScene()
                    }
                }
            } else {
                // check if we've previously logged in within a threshold of time
                let threshold = Date(timeIntervalSinceNow: -60 * 60) // one hour?
                let userId = AppSettings.userId
                let agencyId = AppSettings.agencyId
                let sceneId = AppSettings.sceneId
                if userId != nil && agencyId != nil, let sceneId = sceneId {
                    if let lastScenePingDate = AppSettings.lastScenePingDate, lastScenePingDate > threshold {
                        DispatchQueue.main.async {
                            AppDelegate.enterScene(id: sceneId)
                        }
                        return
                    }
                }
                if userId != nil && agencyId != nil {
                    if let lastPingDate = AppSettings.lastPingDate, lastPingDate > threshold {
                        DispatchQueue.main.async {
                            _ = AppDelegate.leaveScene()
                        }
                        return
                    }
                }
                // otherwise, display error and force re-login on next retry
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if let error = error {
                        self.presentAlert(error: error)
                    } else {
                        self.presentUnexpectedErrorAlert()
                    }
                    self.retryButton.isHidden = false
                }
            }
        }
    }
}
