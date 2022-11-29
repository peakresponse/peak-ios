//
//  SceneTabBarController.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit
import RealmSwift
import PRKit

class SceneTabBarController: CustomTabBarController {
    var results: Results<Scene>?
    var notificationToken: NotificationToken?

    deinit {
        AppRealm.disconnectScene()
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        customTabBar.buttonTitle = "Button.scanPatient".localized

        if let sceneId = AppSettings.sceneId {
            // disconnect from agency updates
            AppRealm.disconnectIncidents()
            // conenct to scene updates
            AppRealm.connect(sceneId: sceneId)

            let realm = AppRealm.open()
            results = realm.objects(Scene.self).filter("id=%@", sceneId)
            notificationToken = results?.observe({ [weak self] (changes) in
                self?.didObserveChanges(changes)
            })
        }
    }

    func didObserveChanges(_ change: RealmCollectionChange<Results<Scene>>) {
        switch change {
        case .initial:
            break
        case .update(_, deletions: _, insertions: _, modifications: _):
            if let results = results, results.count > 0 {
                let scene = results[0]
                if scene.closedAt != nil {
                    let vc = ModalViewController()
                    vc.messageText = "SceneTabBarController.closed.message".localized
                    vc.addAction(UIAlertAction(title: "Button.ok".localized, style: .default, handler: { [weak self] (_) in
                        self?.dismiss(animated: true, completion: {
                            _ = AppDelegate.leaveScene()
                        })
                    }))
                    presentAnimated(vc)
                }
            }
        case .error(let error):
            presentAlert(error: error)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print(segue)
    }

    // MARK: - CustomTabBarDelegate

    override func customTabBar(_ tabBar: CustomTabBar, didPress button: UIButton) {
        let vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Scan")
        if let vc = vc as? ScanViewController {
            vc.incident = results?.first?.incident.first
        }
        presentAnimated(vc)
    }
}
