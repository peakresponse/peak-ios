//
//  SceneOverviewViewController.swift
//  Triage
//
//  Created by Francis Li on 9/2/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit
import PRKit

class SceneOverviewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
                                   SceneOverviewCounterCellDelegate {
    @IBOutlet weak var collectionView: UICollectionView!

    private var scene: Scene?
    private var notificationToken: NotificationToken?
    private var isExpectantHidden = true

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        tabBarItem.title = "TabBarItem.sceneOverview".localized
        tabBarItem.image = UIImage(named: "Dashboard", in: PRKitBundle.instance, compatibleWith: nil)
    }

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 120)
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }

        guard let sceneId = AppSettings.sceneId else { return }
        let realm = AppRealm.open()
        scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
        notificationToken = scene?.observe { [weak self] (change) in
            self?.didObserveChange(change)
        }
    }

    func didObserveChange(_ change: ObjectChange<Scene>) {
        switch change {
        case .change:
            refresh()
        case .error(let error):
            presentAlert(error: error)
        case .deleted:
            leaveScene()
        }
    }

    private func leaveScene() {
        _ = AppDelegate.leaveScene()
    }

    private func refresh() {
        guard let scene = scene else { return }
        for cell in collectionView.visibleCells {
            if let cell = cell as? SceneOverviewCell {
                cell.configure(from: scene)
            }
        }
    }

    @IBAction func editPressed(_ sender: Any) {
        guard let scene = scene else { return }
        let vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Location")
        if let vc = vc as? LocationViewController {
            vc.modalPresentationStyle = .fullScreen
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized, style: .plain, target: self, action: #selector(dismissAnimated))
            vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "NavigationBar.save".localized, style: .done, target: self, action: #selector(saveScenePressed))
            vc.scene = scene
            vc.newScene = Scene(clone: scene)
            _ = vc.view
            vc.isEditing = true
        }
        presentAnimated(vc)
    }

    @IBAction func notePressed(_ sender: Any) {
    }

    @IBAction func photoPressed(_ sender: Any) {
    }

    @IBAction func joinPressed(_ sender: Any) {
        guard let sceneId = scene?.id else { return }
        AppRealm.joinScene(sceneId: sceneId) { (error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error: error)
                }
            }
        }
    }

    @IBAction func transferPressed(_ sender: Any) {
    }

    @IBAction func closePressed(_ sender: Any) {
        guard let scene = scene else { return }
        let sceneId = scene.id
        if scene.mgsResponder?.user?.id == AppSettings.userId {
            let vc = ModalViewController()
            vc.isDismissedOnAction = false
            vc.messageText = "CloseSceneConfirmation.message".localized
            vc.addAction(UIAlertAction(title: "Button.close".localized, style: .destructive, handler: { [weak self] (_) in
                guard let self = self else { return }
                AppRealm.endScene(sceneId: sceneId) { [weak self] (error) in
                    DispatchQueue.main.async { [weak self] in
                        vc.dismissAnimated()
                        if let error = error {
                            self?.presentAlert(error: error)
                        } else {
                            self?.leaveScene()
                        }
                    }
                }
            }))
            vc.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel))
            presentAnimated(vc)
        } else {
            if scene.isResponder(userId: AppSettings.userId) {
                AppRealm.leaveScene(sceneId: sceneId) { _ in
                }
            }
            leaveScene()
        }
    }

    @objc func saveScenePressed() {
        if let vc = presentedViewController as? LocationViewController {
            if let scene = vc.newScene {
                AppRealm.updateScene(scene: scene)
            }
            dismissAnimated()
        }
    }

    // MARK: - SceneOverviewCounterCellDelegate

    func counterCell(_ cell: SceneOverviewCounterCell, didChange value: Int, for priority: TriagePriority?) {
        guard let sceneId = scene?.id else { return }
        AppRealm.updateApproxPatientsCounts(sceneId: sceneId, priority: priority, value: value)
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: // header
            return 1
        case 1: // approx triage counts header
            return 1
        case 2: // triage counters
            return isExpectantHidden ? 5 : 6
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell
        switch indexPath.section {
        case 0:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SceneOverviewHeader", for: indexPath)
        case 1:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SceneOverviewTriageTotal", for: indexPath)
        case 2:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SceneOverviewCounter", for: indexPath)
            if let cell = cell as? SceneOverviewCounterCell {
                cell.delegate = self
                if indexPath.row > 0 {
                    var value = indexPath.row - 1
                    if isExpectantHidden && value >= TriagePriority.expectant.rawValue {
                        value += 1
                    }
                    cell.priority = TriagePriority(rawValue: value)
                } else {
                    cell.priority = nil
                }
            }
        default:
            cell = UICollectionViewCell()
        }
        if let cell = cell as? SceneOverviewCell, let scene = scene {
            cell.configure(from: scene)
        }
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 1 {
            return UIEdgeInsets(top: 1, left: 20, bottom: 0, right: 20)
        }
        return UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    }
}
