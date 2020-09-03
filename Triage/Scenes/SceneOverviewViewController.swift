//
//  SceneOverviewViewController.swift
//  Triage
//
//  Created by Francis Li on 9/2/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

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

    private var scene: Scene?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneCommandsView.addShadow(withOffset: CGSize(width: 0, height: 6), radius: 20, color: .black, opacity: 0.1)
        
        if let tableHeaderView = tableView.tableHeaderView {
            tableHeaderView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableHeaderView.widthAnchor.constraint(equalTo: tableView.widthAnchor)
            ])
        }

        if let sceneId = AppSettings.sceneId {
            scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId)
        }
        
        refresh();
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        /// hack to trigger appropriate autolayout for header view- assign again, then trigger a second layout of just the tableView
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.layoutIfNeeded()
    }

    private func refresh() {
        if let scene = scene {
            sceneHeaderView.configure(from: scene)
            scenePatientsView.configure(from: scene)
            sceneRespondersView.configure(from: scene)
        }
    }
}
