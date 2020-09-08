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
    @IBOutlet weak var transferButton: FormButton!
    @IBOutlet weak var scenePatientsView: ScenePatientsView!
    @IBOutlet weak var sceneRespondersView: SceneRespondersView!

    private var scene: Scene!
    var notificationToken: NotificationToken?
    
    deinit {
        notificationToken?.invalidate()
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
        scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId)
        notificationToken = scene.observe { [weak self] (change) in
            self?.didObserveChange(change)
        }
        refresh();
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        /// hack to trigger appropriate autolayout for header view- assign again, then trigger a second layout of just the tableView
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.layoutIfNeeded()
    }
    
    func didObserveChange(_ change: ObjectChange) {
        switch change {
        case .change(_):
            refresh();
        case .error(let error):
            presentAlert(error: error)
        case .deleted:
            close()
        }
    }

    private func refresh() {
        sceneHeaderView.configure(from: scene)
        scenePatientsView.configure(from: scene)
        sceneRespondersView.configure(from: scene)
    }

    private func close() {
        AppRealm.disconnectScene()
        AppSettings.sceneId = nil
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() {
            for window in UIApplication.shared.windows {
                if window.isKeyWindow {
                    window.rootViewController = vc
                    break
                }
            }
        }
    }
    
    @IBAction func editPressed(_ sender: Any) {
    }

    @IBAction func notePressed(_ sender: Any) {
    }
    
    @IBAction func photoPressed(_ sender: Any) {
    }

    @IBAction func closePressed(_ sender: Any) {
        close()
    }
    
    @IBAction func leavePressed(_ sender: Any) {
        close()
    }

    @IBAction func transferPressed(_ sender: Any) {
    }
}
