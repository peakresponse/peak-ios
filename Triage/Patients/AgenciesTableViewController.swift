//
//  AgenciesTableViewController.swift
//  Triage
//
//  Created by Francis Li on 4/7/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

class AgenciesTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var facilityView: FacilityView!
    @IBOutlet weak var selectLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: SearchBar!
    var debounceTimer: Timer?

    var facility: Facility!

    var notificationToken: NotificationToken?
    var results: Results<Agency>?

    deinit {
        removeKeyboardListener()
        notificationToken?.invalidate()
        debounceTimer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addKeyboardListener()

        facilityView.configure(from: facility)
        facilityView.layer.borderColor = UIColor.greyPeakBlue.cgColor
        facilityView.layer.borderWidth = 2

        selectLabel.font = .copySBold
        selectLabel.textColor = .mainGrey
        selectLabel.text = "AgenciesTableViewController.selectLabel".localized

        tableView.register(FacilityTableViewCell.self, forCellReuseIdentifier: "Facility")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        refresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // hack to trigger appropriate autolayout for header view- assign again, then trigger a second layout of just the tableView
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.layoutIfNeeded()
    }

    @objc override func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            view.layoutIfNeeded()
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
            UIView.animate(withDuration: duration) {
                self.headerViewTopConstraint.constant = 0
                self.tableView.contentInset.bottom = keyboardFrame.height
                self.tableView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc override func keyboardWillHide(_ notification: NSNotification) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25) {
            self.headerViewTopConstraint.constant = 140
            self.tableView.contentInset.bottom = 0
            self.tableView.verticalScrollIndicatorInsets.bottom = 0
            self.view.layoutIfNeeded()
        }
    }

    @objc func refresh() {
        if let refreshControl = tableView.refreshControl, !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()

            var predicates: [NSPredicate] = []
            if let text = searchBar.text, !text.isEmpty {
                predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", text))
            }
            let realm = AppRealm.open()
            notificationToken?.invalidate()
            results = realm.objects(Agency.self)
                .filter(NSCompoundPredicate(andPredicateWithSubpredicates: predicates))
                .sorted(by: [SortDescriptor(keyPath: "name", ascending: true)])
            notificationToken = results?.observe { [weak self] (changes) in
                self?.didObserveRealmChanges(changes)
            }

            AppRealm.getAgencies(search: searchBar.text) { (error) in
                DispatchQueue.main.async {
                    refreshControl.endRefreshing()
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

    @IBAction func unwindToAgencies(_ segue: UIStoryboardSegue) {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ConfirmTransportViewController,
            let indexPath = tableView.indexPathForSelectedRow,
            let agency = results?[indexPath.row] {
            vc.facility = facility
            vc.agency = agency
        }
    }

    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] (_) in
            self?.refresh()
        })
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Facility", for: indexPath)
        if let cell = cell as? FacilityTableViewCell, let agency = results?[indexPath.row] {
            cell.configure(from: agency)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ConfirmTransport", sender: self)
    }
}
