//
//  ICD10CMSectionsViewController.swift
//  Triage
//
//  Created by Francis Li on 12/7/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import RealmSwift
import PRKit

class ICD10CMSectionTableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
}

protocol ICD10CMSectionsViewControllerDelegate: AnyObject {
    func icd10CMSectionsViewController(_ vc: ICD10CMSectionsViewController, checkbox: Checkbox, didChange isChecked: Bool)
}

class ICD10CMSectionsViewController: UITableViewController, ICD10CMItemsViewControllerDelegate {
    weak var delegate: ICD10CMSectionsViewControllerDelegate?

    var isMultiSelect = false
    var values: [String]?
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ICD10CMItemsViewController,
           let indexPath = tableView.indexPathForSelectedRow,
           let section = results?[indexPath.row] {
            vc.delegate = self
            vc.values = values
            vc.isMultiSelect = isMultiSelect
            vc.section = section
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // MARK: - ICD10CMItemsViewControllerDelegate

    func icd10CMItemsViewController(_ vc: ICD10CMItemsViewController, checkbox: Checkbox, didChange isChecked: Bool) {
        delegate?.icd10CMSectionsViewController(self, checkbox: checkbox, didChange: isChecked)
        vc.values = values
    }

    // MARK: - UITableViewDataSource

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
