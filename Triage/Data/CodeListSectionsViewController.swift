//
//  CodeListSectionsViewController.swift
//  Triage
//
//  Created by Francis Li on 12/7/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
internal import RealmSwift
import PRKit

protocol CodeListViewController: AnyObject {
    var values: [NSObject]? { get set }
    func reloadVisible()
}

class CodeListSectionTableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .background
        label.textColor = .text
    }
}

protocol CodeListSectionsViewControllerDelegate: AnyObject {
    func codeListSectionsViewController(_ vc: CodeListSectionsViewController, checkbox: Checkbox, didChange isChecked: Bool)
}

class CodeListSectionsViewController: UITableViewController, CodeListViewController, CodeListItemsViewControllerDelegate {
    weak var delegate: CodeListSectionsViewControllerDelegate?

    var isMultiSelect = false
    var values: [NSObject]?
    var list: CodeList?
    var includeSystem = false
    var results: Results<CodeListSection>?
    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = .background
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
            if results?.count == 0 {
                let vc = UIStoryboard(name: "CodeList", bundle: nil).instantiateViewController(withIdentifier: "Items")
                if let vc = vc as? CodeListItemsViewController {
                    vc.list = list
                    vc.includeSystem = includeSystem
                    vc.delegate = self
                    vc.values = values
                    vc.isMultiSelect = isMultiSelect
                }
                navigationController?.pushViewController(vc, animated: false)
            }
        case .update(_, let deletions, let insertions, let modifications):
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            self.tableView.endUpdates()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CodeListItemsViewController,
           let indexPath = tableView.indexPathForSelectedRow,
           let section = results?[indexPath.row] {
            vc.delegate = self
            vc.values = values
            vc.isMultiSelect = isMultiSelect
            vc.section = section
            vc.includeSystem = includeSystem
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // MARK: - CodeListItemsViewControllerDelegate

    func codeListItemsViewController(_ vc: CodeListItemsViewController, checkbox: Checkbox, didChange isChecked: Bool) {
        delegate?.codeListSectionsViewController(self, checkbox: checkbox, didChange: isChecked)
    }

    // MARK: - CodeListViewController

    func reloadVisible() {

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
        if let cell = cell as? CodeListSectionTableViewCell {
            cell.label.text = results?[indexPath.row].name
        }
        return cell
    }
}
