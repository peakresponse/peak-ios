//
//  TransportReportsViewController.swift
//  Triage
//
//  Created by Francis Li on 3/6/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
internal import RealmSwift
import UIKit

@objc protocol TransportReportsViewControllerDelegate {
    @objc optional func transportReportsViewController(_ vc: TransportReportsViewController, didSelect report: Report?)
}

class TransportReportsViewController: UIViewController, TransportCartViewController,
                                      PRKit.FormFieldDelegate, ScanViewControllerDelegate,
                                      UITableViewDataSource, UITableViewDelegate {
    weak var contentView: UIView!
    weak var tableView: UITableView!
    weak var addButton: RoundButton!

    weak var delegate: TransportReportsViewControllerDelegate?
    var cart: TransportCart?

    var incident: Incident?
    var results: Results<Report>?
    var filteredResults: Results<Report>?
    var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        let tableView = TableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .background
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.register(ReportTableViewCell.self, forCellReuseIdentifier: "Report")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.tableView = tableView

        let addButton = RoundButton(frame: CGRect(x: 0, y: 0, width: 94, height: 94))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Button.scanTag".localized, for: .normal)
        addButton.addTarget(self, action: #selector(addPressed(_:)), for: .touchUpInside)
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 94),
            addButton.heightAnchor.constraint(equalToConstant: 94),
            addButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
        self.addButton = addButton

        isEditing = incident?.scene?.isResponder(userId: AppSettings.userId) ?? false
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        addButton.isHidden = !isEditing
        for cell in tableView.visibleCells {
            if let cell = cell as? ReportTableViewCell {
                cell.checkbox.isEnabled = isEditing
                cell.checkbox.isUserInteractionEnabled = false
            }
        }
    }

    @objc func performQuery(_ searchText: String? = nil) {
        guard let incident = incident else { return }

        notificationToken?.invalidate()

        let realm = AppRealm.open()
        results = realm.objects(Report.self)
            .filter("incident=%@ AND canonicalId=%@ AND deletedAt=%@", incident, NSNull(), NSNull())
        filteredResults = results
        if let searchText = searchText, !searchText.isEmpty {
            filteredResults = filteredResults?.filter("(pin CONTAINS[cd] %@) OR (patient.firstName CONTAINS[cd] %@) OR (patient.lastName CONTAINS[cd] %@)",
                                                      searchText, searchText, searchText)
        }
        filteredResults = filteredResults?.sorted(by: [
            SortDescriptor(keyPath: "filterPriority"),
            SortDescriptor(keyPath: "updatedAt")
        ])
        notificationToken = filteredResults?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
        refresh()
    }

    @objc func refresh() {
        guard let incident = incident else { return }
        tableView.refreshControl?.beginRefreshing()
        AppRealm.getReports(incident: incident) { [weak self] (_, error) in
            guard let self = self else { return }
            if let error = error {
                print(error)
            }
            self.tableView.refreshControl?.endRefreshing()
        }
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Report>>) {
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

    @objc func addPressed(_ sender: RoundButton) {
        let vc = ScanViewController()
        vc.delegate = self
        presentAnimated(vc)
    }

    func updateCart() {

    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        performQuery()
    }

    func formFieldShouldReturn(_ field: PRKit.FormField) -> Bool {
        field.resignFirstResponder()
        return false
    }

    // MARK: - ScanViewControllerDelegate

    func scanViewController(_ vc: ScanViewController, didScan pin: String, report: Report?) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            if let report = report {
                self.delegate?.transportReportsViewController?(self, didSelect: report)
                if let index = filteredResults?.firstIndex(of: report) {
                    let indexPath = IndexPath(row: index, section: 0)
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                    tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                }
            } else {
                self.presentAlert(title: "TransportReportsViewController.notFound.title".localized,
                                  message: String(format: "TransportReportsViewController.notFound.message".localized, pin))
            }
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredResults?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Report", for: indexPath)
        if let cell = cell as? ReportTableViewCell, let report = filteredResults?[indexPath.row] {
            cell.configure(report: report, index: indexPath.row, selected: cart?.reports.contains(report) ?? false)
            cell.checkbox.isEnabled = isEditing
            cell.checkbox.isUserInteractionEnabled = false
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ReportTableViewCell {
            cell.constrain(to: contentView)
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isEditing, let report = filteredResults?[indexPath.row] {
            delegate?.transportReportsViewController?(self, didSelect: report)
            if let cell = tableView.cellForRow(at: indexPath) as? ReportTableViewCell {
                cell.configure(report: report, index: indexPath.row, selected: cart?.reports.contains(report) ?? false)
            }
        }
    }
}
