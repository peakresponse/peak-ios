//
//  InterstitialViewController.swift
//  Triage
//
//  Created by Francis Li on 4/5/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import UIKit

class InterstitialViewController: UIViewController {
    weak var logoView: UIImageView!
    weak var activityIndicatorView: UIActivityIndicatorView!
    weak var retryButton: PRKit.Button!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .bgBackground

        let logoView = UIImageView()
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.image = UIImage(named: "Logo")
        view.addSubview(logoView)
        NSLayoutConstraint.activate([
            logoView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            logoView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 22),
            logoView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -22),
            logoView.widthAnchor.constraint(lessThanOrEqualToConstant: 332),
            logoView.heightAnchor.constraint(equalTo: logoView.widthAnchor, multiplier: 88.0 / 332.0)
        ])
        self.logoView = logoView

        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 75),
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
        activityIndicatorView.startAnimating()
        self.activityIndicatorView = activityIndicatorView

        let retryButton = PRKit.Button()
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.style = .primary
        retryButton.setTitle("Button.retry".localized, for: .normal)
        retryButton.addTarget(self, action: #selector(retryPressed(_:)), for: .touchUpInside)
        retryButton.isHidden = true
        view.addSubview(retryButton)
        NSLayoutConstraint.activate([
            retryButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: activityIndicatorView.centerYAnchor)
        ])
        self.retryButton = retryButton

        checkLoginStatus()
    }

    @objc func retryPressed(_ sender: Any) {
        checkLoginStatus()
        retryButton.isHidden = true
    }

    func checkLoginStatus() {
        // hit the server to check current log-in status
        AppRealm.me { [weak self] (user, agency, assignment, vehicle, scene, awsCredentials, error) in
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
