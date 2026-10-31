//
//  FormsViewController.swift
//  Triage
//
//  Created by Francis Li on 9/15/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation
import UIKit
import PRKit
internal import RealmSwift

@objc protocol FormsViewControllerDelegate: AnyObject {
    @objc optional func formsViewController(_ vc: FormsViewController, didCollect signatures: [Signature])
}

class FormsViewController: BaseViewController, FormViewControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var tableView: UITableView!

    weak var delegate: FormsViewControllerDelegate?

    var results: Results<Form>?
    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let commandHeader = CommandHeader()
        commandHeader.translatesAutoresizingMaskIntoConstraints = false
        commandHeader.preservesSuperviewLayoutMargins = true
        headerView.addSubview(commandHeader)
        NSLayoutConstraint.activate([
            commandHeader.topAnchor.constraint(equalTo: headerView.topAnchor),
            commandHeader.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            commandHeader.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            commandHeader.contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            commandHeader.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            headerView.bottomAnchor.constraint(equalTo: commandHeader.bottomAnchor)
        ])
        self.commandHeader = commandHeader

        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .background
        tableView.dataSource = self
        tableView.delegate = self
        mainView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: mainView.topAnchor),
            tableView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
        ])
        self.tableView = tableView

        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized,
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(dismissAnimated))

        tableView.register(ListItemTableViewCell.self, forCellReuseIdentifier: "Form")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 62

        performQuery()
    }

    func performQuery() {
        notificationToken?.invalidate()
        let realm = AppRealm.open()
        results = realm.objects(Form.self)
        results = results?.sorted(byKeyPath: "title", ascending: true)
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Form>>) {
        switch changes {
        case .initial:
            tableView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            tableView.performBatchUpdates({
                self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            }, completion: nil)
        case .error(let error):
            presentAlert(error: error)
        }
    }

    @objc func backPressed() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - FormViewController

    func formViewController(_ vc: FormViewController, didCollect signatures: [Signature]) {
        delegate?.formsViewController?(self, didCollect: signatures)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Form", for: indexPath)
        if let cell = cell as? ListItemTableViewCell {
            cell.label.text = results?[indexPath.row].title
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Form")
        if let vc = vc as? FormViewController {
            let backButton = UIBarButtonItem(title: "Button.back".localized, style: .plain, target: self, action: #selector(backPressed))
            backButton.image = UIImage(named: "ChevronLeft40px", in: PRKitBundle.instance, compatibleWith: nil)
            vc.navigationItem.leftBarButtonItem = backButton
            vc.delegate = self
            vc.form = results?[indexPath.row]
            vc.report = Report.newRecord()
            vc.isEditing = true
        }
        navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
