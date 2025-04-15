//
//  SceneTabBarController.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
import UIKit
internal import RealmSwift
import PRKit

class SceneTabBarController: CustomTabBarController, LocationHelperDelegate {
    var results: Results<Scene>?
    var notificationToken: NotificationToken?

    deinit {
        LocationHelper.instance.removeDelegate(self)
        AppRealm.disconnectScene()
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let realm = AppRealm.open()
        if let sceneId = AppSettings.sceneId, let scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId), scene.isActive {
            // disconnect from agency updates
            AppRealm.disconnectIncidents()
            // connect to scene updates
            AppRealm.connect(sceneId: sceneId)

            results = realm.objects(Scene.self).filter("id=%@", sceneId)
            notificationToken = results?.observe({ [weak self] (changes) in
                self?.didObserveChanges(changes)
            })

            LocationHelper.instance.addDelegate(self)
            // if latest location available and scene address empty, set as scene address
            if scene.isAddressEmpty, let location = LocationHelper.instance.latestLocation {
                locationHelper(LocationHelper.instance, didUpdateLocations: [location])
            }
            // get an initial location fix
            LocationHelper.instance.requestLocation()
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

    // MARK: - LocationHelperDelegate

    func locationHelper(_ helper: LocationHelper, didUpdateLocations locations: [CLLocation]) {
        // if no address set yet, reverse geocode and save
        if let scene = results?.first, scene.isAddressEmpty, let location = locations.last {
            let sceneId = scene.id
            AppRealm.geocode(location: location.coordinate) { [weak self] (data, _) in
                guard let _ = self, let data = data else { return }
                let realm = AppRealm.open()
                // double-check and make sure scene address hasn't been set in the meantime
                guard let scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId), scene.isAddressEmpty else { return }
                let newScene = Scene(clone: scene)
                if let address1 = data["address1"] as? String {
                    newScene.address1 = address1
                }
                if let cityId = data["cityId"] as? String {
                    newScene.cityId = cityId
                }
                if let stateId = data["stateId"] as? String {
                    newScene.stateId = stateId
                }
                if let zip = data["zip"] as? String {
                    newScene.zip = zip
                }
                AppRealm.updateScene(scene: newScene)
            }
        }
    }

    func locationHelper(_ helper: LocationHelper, didFailWithError error: any Error) {

    }
}
