//
//  AgenciesTableViewController.swift
//  Triage
//
//  Created by Francis Li on 4/7/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

class AgenciesTableViewController: UITableViewController, FilterViewDelegate {
    @IBOutlet weak var filterView: FilterView!

    var observation: Observation?
    var handler: ((AgenciesTableViewController) -> ())?
    
    var notificationToken: NotificationToken?
    var results: Results<Agency>?

    deinit {
        notificationToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        filterView.button.isHidden = true
        filterView.delegate = self
        
        tableView.register(UINib(nibName: "FacilityTableViewCell", bundle: nil), forCellReuseIdentifier: "Facility")
        tableView.tableFooterView = UIView()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refresh()
    }

    @objc func refresh() {
        if let refreshControl = refreshControl, !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()

            var predicates: [NSPredicate] = []
            if let text = filterView.textField.text, !text.isEmpty {
                predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", text))
            }
            let realm = AppRealm.open()
            results = realm.objects(Agency.self)
                .filter(NSCompoundPredicate(andPredicateWithSubpredicates: predicates))
                .sorted(by: [SortDescriptor(keyPath: "name", ascending: true)])
            notificationToken = results?.observe { [weak self] (changes) in
                self?.didObserveRealmChanges(changes)
            }

            AppRealm.getAgencies(search: filterView.textField.text) { (error) in
                DispatchQueue.main.async { [weak self] in
                    self?.refreshControl?.endRefreshing()
                }
                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        self?.presentAlert(error: error)
                    }
                }
            }
        }
    }
    
    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Agency>>) {
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
    
    // MARK: - FilterViewDelegate

    func filterView(_ filterView: FilterView, didChangeSearch text: String?) {
        refresh()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Facility", for: indexPath)
        if let cell = cell as? FacilityTableViewCell, let agency = results?[indexPath.row] {
            cell.configure(from: agency)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let agency = results?[indexPath.row] {
            return FacilityTableViewCell.height(for: agency)
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let agency = results?[indexPath.row] {
            observation?.transportAgency = agency
        }
        handler?(self)
    }
}
