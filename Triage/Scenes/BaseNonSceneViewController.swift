//
//  BaseNonSceneViewController.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

class BaseNonSceneViewController: UIViewController {
    @IBOutlet weak var bannerView: BannerView!
    @IBOutlet weak var activeScenesView: ActiveScenesView!

    var activeScenesNotificationToken: NotificationToken?
    var activeScenesResults: Results<Scene>?

    deinit {
        activeScenesNotificationToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        case .initial(_):
            updateActiveScenesViews()
        case .update(_, _, _, _):
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
}
