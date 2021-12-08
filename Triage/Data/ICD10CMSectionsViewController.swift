//
//  ICD10CMSectionsViewController.swift
//  Triage
//
//  Created by Francis Li on 12/7/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import RealmSwift

class ICD10CMSectionTableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
}

class ICD10CMSectionsViewController: UITableViewController {
    var list: CodeList?
    var results: Results<CodeListSection>?
    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        let realm = AppRealm.open()
        results = realm.objects(CodeListSection.self).filter("list=%@", list as Any).sorted(by: [
            SortDescriptor(keyPath: "position", ascending: true),
            SortDescriptor(keyPath: "name", ascending: true)
        ])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<CodeListSection>>) {
        switch changes {
        case .initial:
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Section", for: indexPath)
        if let cell = cell as? ICD10CMSectionTableViewCell {
            cell.label.text = results?[indexPath.row].name
        }
        return cell
    }
}
