//
//  SceneOverviewViewController.swift
//  Triage
//
//  Created by Francis Li on 9/2/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

class SceneOverviewViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sceneHeaderView: SceneHeaderView!
    @IBOutlet weak var sceneCommandsView: UIView!
    @IBOutlet weak var closeButton: FormButton!
    @IBOutlet weak var leaveButton: FormButton!
    @IBOutlet weak var exitButton: FormButton!
    @IBOutlet weak var joinButton: FormButton!
    @IBOutlet weak var transferButton: FormButton!
    @IBOutlet weak var scenePatientsView: ScenePatientsView!
    @IBOutlet weak var sceneRespondersView: SceneRespondersView!
    @IBOutlet weak var addNoteButton: FormButton!
    @IBOutlet weak var addPhotoButton: FormButton!

    private var scene: Scene!
    private var notificationToken: NotificationToken?
    private var responders: Results<Responder>!
    private var respondersNotificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
        respondersNotificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneCommandsView.addShadow(withOffset: CGSize(width: 0, height: 6), radius: 20, color: .black, opacity: 0.1)

        if let tableHeaderView = tableView.tableHeaderView {
            tableHeaderView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableHeaderView.widthAnchor.constraint(equalTo: tableView.widthAnchor)
            ])
        }

        guard let sceneId = AppSettings.sceneId else { return }
        AppRealm.getScene(sceneId: sceneId) { [weak self] (scene, error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error: error)
                }
            } else if let sceneId = scene?.id {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let realm = AppRealm.open()
                    self.scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
                    self.notificationToken = self.scene.observe { [weak self] (change) in
                        self?.didObserveChange(change)
                    }
                    self.responders = realm.objects(Responder.self).filter("scene.id=%@ AND user.id=%@ AND departedAt=NULL",
                                                                           sceneId,
                                                                           AppSettings.userId ?? "")
                    self.respondersNotificationToken = self.responders.observe { [weak self] (change) in
                        self?.didObserveRespondersChange(change)
                    }
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // hack to trigger appropriate autolayout for header view- assign again, then trigger a second layout of just the tableView
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.layoutIfNeeded()
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

    func didObserveRespondersChange(_ change: RealmCollectionChange<Results<Responder>>) {
        switch change {
        case .initial:
            refresh()
        case .update(_, deletions: _, insertions: _, modifications: _):
            refresh()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    private func leaveScene() {
        AppDelegate.leaveScene()
    }

    private func refresh() {
        sceneHeaderView.configure(from: scene)
        scenePatientsView.configure(from: scene)
        sceneRespondersView.configure(from: scene)
        if AppSettings.userId == scene.incidentCommanderId {
            closeButton.isHidden = false
            leaveButton.isHidden = true
            exitButton.isHidden = true
            joinButton.isHidden = true
            // for now, hide transfer button, leave space for sizing
            transferButton.isHidden = false
            transferButton.alpha = 0
        } else {
            closeButton.isHidden = true
            if responders.count > 0 {
                leaveButton.isHidden = false
                exitButton.isHidden = true
                joinButton.isHidden = true
                transferButton.isHidden = false
                transferButton.alpha = 0
            } else {
                leaveButton.isHidden = true
                exitButton.isHidden = false
                joinButton.isHidden = false
                transferButton.isHidden = true
            }
        }
    }

    @IBAction func editPressed(_ sender: Any) {
    }

    @IBAction func notePressed(_ sender: Any) {
    }

    @IBAction func photoPressed(_ sender: Any) {
    }

    @IBAction func joinPressed(_ sender: Any) {
        AppRealm.joinScene(sceneId: scene.id) { (error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error: error)
                }
            }
        }
    }

    @IBAction func exitPressed(_ sender: Any) {
        DispatchQueue.main.async {
            AppDelegate.leaveScene()
        }
    }

    @IBAction func closePressed(_ sender: Any) {
        let sceneId = scene.id
        let vc = AlertViewController()
        vc.alertTitle = String(format: "CloseSceneConfirmation.title".localized, scene.name ?? "")
        vc.alertMessage = "CloseSceneConfirmation.message".localized
        vc.addAlertAction(title: "Button.cancel".localized, style: .cancel, handler: nil)
        vc.addAlertAction(title: "Button.close".localized, style: .default) { [weak self] (_) in
            guard let self = self else { return }
            AppRealm.closeScene(sceneId: sceneId) { [weak self] (error) in
                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        self?.presentAlert(error: error)
                    }
                } else {
                    DispatchQueue.main.async {
                        AppDelegate.leaveScene()
                    }
                }
            }
        }
        presentAnimated(vc)
    }

    @IBAction func leavePressed(_ sender: Any) {
        let sceneId = scene.id
        let vc = AlertViewController()
        vc.alertTitle = String(format: "LeaveSceneConfirmation.title".localized, scene.name ?? "")
        vc.alertMessage = "LeaveSceneConfirmation.message".localized
        vc.addAlertAction(title: "Button.cancel".localized, style: .cancel, handler: nil)
        vc.addAlertAction(title: "Button.leave".localized, style: .default) { [weak self] (_) in
            guard let self = self else { return }
            AppRealm.leaveScene(sceneId: sceneId) { [weak self] (error) in
                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        self?.presentAlert(error: error)
                    }
                } else {
                    DispatchQueue.main.async {
                        AppDelegate.leaveScene()
                    }
                }
            }
        }
        presentAnimated(vc)
    }

    @IBAction func transferPressed(_ sender: Any) {
    }
}
