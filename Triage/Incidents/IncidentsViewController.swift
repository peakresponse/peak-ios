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

class IncidentsViewController: UIViewController, AssignmentViewControllerDelegate, CommandHeaderDelegate, PRKit.FormFieldDelegate,
                               UITableViewDataSource, UITableViewDelegate {
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

        setCommandHeaderUser(userId: AppSettings.userId, assignmentId: AppSettings.assignmentId)
        commandHeader.searchField.delegate = self

        let segmentedControl = SegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addSegment(title: "IncidentsViewController.mine".localized)
        segmentedControl.addSegment(title: "IncidentsViewController.all".localized)
        segmentedControl.addTarget(self, action: #selector(performQuery), for: .valueChanged)
        if traitCollection.horizontalSizeClass == .regular {
            commandHeader.stackView.insertArrangedSubview(segmentedControl, at: 1)
            commandHeader.stackView.distribution = .fillProportionally
            commandHeader.userButton.widthAnchor.constraint(equalTo: commandHeader.widthAnchor, multiplier: 0.25).isActive = true
            commandHeader.searchField.widthAnchor.constraint(equalTo: commandHeader.widthAnchor, multiplier: 0.25).isActive = true
        } else {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 56))
            view.addSubview(segmentedControl)
            NSLayoutConstraint.activate([
                segmentedControl.topAnchor.constraint(equalTo: view.topAnchor),
                segmentedControl.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
                segmentedControl.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
                view.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor)
            ])
            tableView.tableHeaderView = view
        }
        self.segmentedControl = segmentedControl

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.register(IncidentTableViewCell.self, forCellReuseIdentifier: "Incident")

        performQuery()

        AppRealm.connect()
    }

    func setCommandHeaderUser(userId: String?, assignmentId: String?) {
        if let userId = userId {
            let realm = AppRealm.open()
            let user = realm.object(ofType: User.self, forPrimaryKey: userId)
            AppCache.cachedImage(from: user?.iconUrl) { [weak self] (image, _) in
                let image = image?.rounded()
                DispatchQueue.main.async { [weak self] in
                    self?.commandHeader.userImage = image
                }
            }
            var userLabelText = user?.fullName
            if let assignmentId = assignmentId,
               let assignment = realm.object(ofType: Assignment.self, forPrimaryKey: assignmentId),
               let vehicleId = assignment.vehicleId,
               let vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId) {
                userLabelText = "\(vehicle.number ?? ""): \(userLabelText ?? "")"
            }
            commandHeader.userLabelText = userLabelText
        }
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
                if segmentedControl.segmentsCount < 2 {
                    segmentedControl.insertSegment(title: "IncidentsViewController.mine".localized, at: 0)
                }
                if segmentedControl.selectedIndex == 0 {
                    results = results?.filter("ANY dispatches.vehicleId=%@", vehicleId)
                }
            } else {
                if segmentedControl.segmentsCount > 1 {
                    segmentedControl.removeSegment(at: 0)
                }
            }
        }
        if let text = commandHeader.searchField.text, !text.isEmpty {
            results = results?.filter("(number CONTAINS[cd] %@) OR (scene.address1 CONTAINS[cd] %@) OR (scene.address2 CONTAINS[cd] %@)",
                                      text, text, text)
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
        AppRealm.getIncidents(vehicleId: vehicleId, search: commandHeader.searchField.text,
                              completionHandler: { [weak self] (nextUrl, error) in
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
        setCommandHeaderUser(userId: AppSettings.userId, assignmentId: assignmentId)
        performQuery()
        dismissAnimated()
    }

    // MARK: - CommandHeaderDelegate

    func commandHeaderDidPressUser(_ header: CommandHeader) {
        toggleSidebar()
    }

    // MARK: - FormFieldDelegate

    func formFieldDidChange(_ field: PRKit.FormField) {
        performQuery()
    }

    func formFieldShouldReturn(_ field: PRKit.FormField) -> Bool {
        field.resignFirstResponder()
        return false
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
            let vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Reports")
            if let vc = vc as? ReportsViewController {
                vc.incident = results?[indexPath.row]
            }
            present(vc, animated: true) {
                tableView.deselectRow(at: indexPath, animated: false)
            }
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
