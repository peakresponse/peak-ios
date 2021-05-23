//
//  BaseNonSceneViewController.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

class BaseNonSceneViewController: UIViewController, ActiveScenesViewDelegate {
    @IBOutlet weak var bannerView: BannerView!
    @IBOutlet weak var activeScenesView: ActiveScenesView!

    var activeScenesNotificationToken: NotificationToken?
    var activeScenesResults: Results<Scene>?

    deinit {
        activeScenesNotificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let portraitView = PortraitView()
        portraitView.translatesAutoresizingMaskIntoConstraints = false
        if let userId = AppSettings.userId {
            let user = AppRealm.open().object(ofType: User.self, forPrimaryKey: userId)
            portraitView.configure(from: user)
        }
        let view = UIView()
        view.addSubview(portraitView)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userPressed)))
        let barButtonItem = UIBarButtonItem(customView: view)
        navigationItem.rightBarButtonItem = barButtonItem
        NSLayoutConstraint.activate([
            portraitView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8),
            portraitView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            view.widthAnchor.constraint(equalTo: portraitView.widthAnchor)
        ])

        activeScenesView.delegate = self

        let realm = AppRealm.open()
        activeScenesResults = realm.objects(Scene.self)
            .filter("closedAt == NULL")
            .sorted(by: [SortDescriptor(keyPath: "createdAt", ascending: false)])
        activeScenesNotificationToken = activeScenesResults?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
    }

    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Scene>>) {
        switch changes {
        case .initial:
            updateActiveScenesViews()
        case .update:
            updateActiveScenesViews()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    @objc func userPressed() {
        let alert = UIAlertController(title: "BaseNonSceneViewController.logout.title".localized,
                                      message: "BaseNonSceneViewController.logout.message".localized,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Button.no".localized, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Button.yes".localized, style: .destructive, handler: { [weak self] (_) in
            self?.logout()
        }))
        presentAnimated(alert)
    }

    func updateActiveScenesViews() {
        if let activeScenesResults = activeScenesResults, activeScenesResults.count > 0 {
            bannerView.isHidden = true
            activeScenesView.isHidden = false
            activeScenesView.configure(from: activeScenesResults)
        } else {
            bannerView.isHidden = false
            activeScenesView.isHidden = true
        }
    }

    // MARK: - ActiveScenesViewDelegate

    func activeScenesView(_ view: ActiveScenesView, didJoinScene scene: Scene) {
        let sceneId = scene.id
        AppRealm.joinScene(sceneId: sceneId) { [weak self] (error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error: error)
                }
            } else {
                DispatchQueue.main.async {
                    AppDelegate.enterScene(id: sceneId)
                }
            }
        }
    }

    func activeScenesView(_ view: ActiveScenesView, didViewScene scene: Scene) {
        let sceneId = scene.id
        DispatchQueue.main.async {
            AppDelegate.enterScene(id: sceneId)
        }
    }
}
