//
//  PreviousScenesViewController.swift
//  Triage
//
//  Created by Francis Li on 9/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

class PreviousScenesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var bannerView: BannerView!
    @IBOutlet weak var tableView: UITableView!

    var notificationToken: NotificationToken?
    var results: Results<Scene>?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(SceneTableViewCell.self, forCellReuseIdentifier: "Scene")
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        let realm = AppRealm.open()
        results = realm.objects(Scene.self)
            .sorted(by: [SortDescriptor(keyPath: "createdAt", ascending: false)])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }

        refresh()
    }
    
    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Scene>>) {
        switch changes {
        case .initial(_):
            tableView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            self.tableView.endUpdates()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    @objc func refresh() {
        tableView.refreshControl?.beginRefreshing()
        AppRealm.getScenes { [weak self] (error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.refreshControl?.endRefreshing()
                    if let error = error as? ApiClientError, error == .unauthorized {
                        self?.presentLogin()
                    } else {
                        self?.presentAlert(error: error)
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.refreshControl?.endRefreshing()
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Scene", for: indexPath)
        if let cell = cell as? SceneTableViewCell, let scene = results?[indexPath.row] {
            cell.configure(from: scene)
        }
        return cell;
    }
}
