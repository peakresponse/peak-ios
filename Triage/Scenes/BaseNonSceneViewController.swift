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
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                DispatchQueue.main.async {
                    AppDelegate.enterScene(id: sceneId)
                }
            }
        }
    }
}
