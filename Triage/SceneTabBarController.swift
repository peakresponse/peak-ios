//
//  SceneTabBarController.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit
import RealmSwift

class SceneTabBarController: TabBarController {
    var results: Results<Scene>?
    var notificationToken: NotificationToken?

    deinit {
        AppRealm.disconnectScene()
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let sceneId = AppSettings.sceneId {
            // disconnect from agency updates
            AppRealm.disconnect()
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
                    let alert = AlertViewController()
                    alert.alertTitle = "SceneTabBarController.closed.title".localized
                    alert.alertMessage = "SceneTabBarController.closed.message".localized
                    alert.addAlertAction(title: "Button.ok".localized, style: .cancel) { [weak self] (_) in
                        self?.dismiss(animated: true, completion: {
                            if let tabBarController = AppDelegate.leaveScene() as? NonSceneTabBarController {
                                let vc = UIStoryboard(name: "Scenes", bundle: nil).instantiateViewController(withIdentifier: "SceneSummary")
                                if let vc = vc as? SceneSummaryViewController {
                                    vc.scene = scene
                                    if let navController = tabBarController.selectedViewController as? NavigationController {
                                        navController.pushViewController(vc, animated: false)
                                    }
                                }
                            }
                        })
                    }
                    presentAnimated(alert)
                }
            }
        case .error(let error):
            presentAlert(error: error)
        }
    }
}
