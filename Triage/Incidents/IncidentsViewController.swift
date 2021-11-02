//
//  IncidentsViewController.swift
//  Triage
//
//  Created by Francis Li on 10/27/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift
import UIKit

class IncidentsViewController: UIViewController, AssignmentViewControllerDelegate, CommandHeaderDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var sidebarTableView: SidebarTableView!
    @IBOutlet weak var sidebarTableViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    weak var segmentedControl: SegmentedControl!

    var notificationToken: NotificationToken?
    var results: Results<Incident>?
    var nextUrl: String?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let userId = AppSettings.userId {
            let realm = AppRealm.open()
            let user = realm.object(ofType: User.self, forPrimaryKey: userId)
            commandHeader.userImageURL = user?.iconUrl
            if let assignmentId = AppSettings.assignmentId,
               let assignment = realm.object(ofType: Assignment.self, forPrimaryKey: assignmentId),
               let vehicleId = assignment.vehicleId,
               let vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId) {
                commandHeader.userLabelText = "\(vehicle.number ?? ""): \(user?.fullName ?? "")"
            }
        }

        let segmentedControl = SegmentedControl()
        segmentedControl.addSegment(title: "IncidentsViewController.mine".localized)
        segmentedControl.addSegment(title: "IncidentsViewController.all".localized)
        segmentedControl.addTarget(self, action: #selector(performQuery), for: .valueChanged)
        if traitCollection.horizontalSizeClass == .regular {
            commandHeader.stackView.insertArrangedSubview(segmentedControl, at: 1)
        } else {
            tableView.tableHeaderView = segmentedControl
        }
        self.segmentedControl = segmentedControl

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.register(IncidentTableViewCell.self, forCellReuseIdentifier: "Incident")

        performQuery()
    }

    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Incident>>) {
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

    @objc func performQuery() {
        notificationToken?.invalidate()

        let realm = AppRealm.open()
        results = realm.objects(Incident.self)
            .sorted(by: [SortDescriptor(keyPath: "number", ascending: false)])
        if let assignmentId = AppSettings.assignmentId {
            let assignment = realm.object(ofType: Assignment.self, forPrimaryKey: assignmentId)
            if let vehicleId = assignment?.vehicleId {
                if segmentedControl.selectedIndex == 0 {
                    results = results?.filter("ANY dispatches.vehicleId=%@", vehicleId)
                }
                segmentedControl.isHidden = false
            } else {
                segmentedControl.isHidden = true
            }
        }
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
        refresh()
    }

    @objc func refresh() {
        tableView.refreshControl?.beginRefreshing()
        var vehicleId: String?
        if segmentedControl.selectedIndex == 0, let assignmentId = AppSettings.assignmentId {
            let assignment = AppRealm.open().object(ofType: Assignment.self, forPrimaryKey: assignmentId)
            vehicleId = assignment?.vehicleId
        }
        AppRealm.getIncidents(vehicleId: vehicleId, search: nil, completionHandler: { [weak self] (nextUrl, error) in
            self?.handleIncidentsResponse(nextUrl: nextUrl, error: error)
        })
    }

    func handleIncidentsResponse(nextUrl: String?, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
                if let error = error as? ApiClientError, error == .unauthorized || error == .forbidden {
                    self?.presentLogin()
                } else {
                    self?.presentAlert(error: error)
                }
            }
        } else {
            self.nextUrl = nextUrl
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
            }
        }
    }

    func toggleSidebar() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            if self?.sidebarTableViewLeadingConstraint.constant == 0 {
                self?.sidebarTableViewLeadingConstraint.constant = -300
            } else {
                self?.sidebarTableViewLeadingConstraint.constant = 0
            }
            self?.view.layoutIfNeeded()
        }
    }

    // MARK: - AssignmentViewControllerDelegate

    func assignmentViewController(_ vc: AssignmentViewController, didCreate assignmentId: String) {
        performQuery()
        dismissAnimated()
    }

    // MARK: - CommandHeaderDelegate

    func commandHeaderDidPressUser(_ header: CommandHeader) {
        toggleSidebar()
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == tableView && scrollView.contentOffset.y >= scrollView.contentSize.height / 2 {
            if let nextUrl = nextUrl {
                self.nextUrl = nil
                AppRealm.getNextIncidents(url: nextUrl) { [weak self] (nextUrl, error) in
                    self?.handleIncidentsResponse(nextUrl: nextUrl, error: error)
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == sidebarTableView {
            return 2
        }
        return results?.count ?? 0
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == sidebarTableView {
            switch indexPath.row {
            case 0:
                let vc = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: "Assignment")
                if let vc = vc as? AssignmentViewController {
                    vc.delegate = self
                }
                present(vc, animated: true) { [weak self] in
                    self?.toggleSidebar()
                }
            case 1:
                logout()
            default:
                break
            }
        } else {

        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == sidebarTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SidebarItem", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Sidebar.item.switch".localized
            case 1:
                cell.textLabel?.text = "Sidebar.item.logOut".localized
            default:
                break
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Incident", for: indexPath)
        if let cell = cell as? IncidentTableViewCell, let incident = results?[indexPath.row] {
            cell.number = "#\(incident.number ?? "")"
            cell.address = incident.scene?.address
            if incident.dispatches.count > 0 {
                let dispatch = incident.dispatches.sorted(byKeyPath: "dispatchedAt", ascending: true)[0]
                cell.date = dispatch.dispatchedAt?.asDateString()
                cell.time = dispatch.dispatchedAt?.asTimeString()
            }
        }
        return cell
    }
}
