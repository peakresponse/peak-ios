//
//  EventsViewController.swift
//  Triage
//
//  Created by Francis Li on 5/5/25.
//  Copyright © 2025 Francis Li. All rights reserved.
//

import Foundation
import PRKit
internal import RealmSwift
import UIKit

class EventsViewController: UIViewController, AssignmentViewControllerDelegate, CommandHeaderDelegate, PRKit.FormFieldDelegate,
                            UITableViewDataSource, UITableViewDelegate {
    weak var commandHeader: CommandHeader!
    weak var sidebarTableView: SidebarTableView!
    weak var sidebarTableViewLeadingConstraint: NSLayoutConstraint!
    weak var versionLabel: UILabel!
    weak var tableView: UITableView!
    weak var segmentedControl: SegmentedControl!

    var notificationToken: NotificationToken?
    var results: Results<Event>?
    var nextUrl: String?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let commandHeader = CommandHeader()
        commandHeader.translatesAutoresizingMaskIntoConstraints = false
        commandHeader.delegate = self
        commandHeader.searchFieldDelegate = self
        view.addSubview(commandHeader)
        NSLayoutConstraint.activate([
            commandHeader.topAnchor.constraint(equalTo: view.topAnchor),
            commandHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            commandHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.commandHeader = commandHeader
        setCommandHeaderUser(userId: AppSettings.userId, assignmentId: AppSettings.assignmentId)

        let sidebarTableView = SidebarTableView()
        sidebarTableView.translatesAutoresizingMaskIntoConstraints = false
        sidebarTableView.dataSource = self
        sidebarTableView.delegate = self
        view.addSubview(sidebarTableView)
        let sidebarTableViewLeadingConstraint = sidebarTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -300)
        NSLayoutConstraint.activate([
            sidebarTableView.topAnchor.constraint(equalTo: commandHeader.bottomAnchor),
            sidebarTableViewLeadingConstraint,
            sidebarTableView.widthAnchor.constraint(equalToConstant: 300),
            sidebarTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.sidebarTableView = sidebarTableView
        self.sidebarTableViewLeadingConstraint = sidebarTableViewLeadingConstraint

        let versionLabel = UILabel()
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.font = .body14Bold
        versionLabel.text = AppSettings.version
        versionLabel.textColor = .interactiveText
        view.addSubview(versionLabel)
        NSLayoutConstraint.activate([
            versionLabel.leadingAnchor.constraint(equalTo: sidebarTableView.leadingAnchor, constant: 20),
            versionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        self.versionLabel = versionLabel

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .background
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.register(EventTableViewCell.self, forCellReuseIdentifier: "Event")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: sidebarTableView.trailingAnchor),
            tableView.widthAnchor.constraint(equalTo: view.widthAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.tableView = tableView

        let segmentedControl = SegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addSegment(title: "EventsViewController.current".localized)
        segmentedControl.addSegment(title: "EventsViewController.past".localized)
        segmentedControl.addTarget(self, action: #selector(performQuery), for: .valueChanged)
        if traitCollection.horizontalSizeClass == .regular {
            commandHeader.stackView.insertArrangedSubview(segmentedControl, at: 1)
            commandHeader.stackView.distribution = .fillProportionally
            commandHeader.userButton.widthAnchor.constraint(equalTo: commandHeader.widthAnchor, multiplier: 0.25).isActive = true
            commandHeader.searchField.widthAnchor.constraint(equalTo: commandHeader.widthAnchor, multiplier: 0.25).isActive = true
            tableView.topAnchor.constraint(equalTo: commandHeader.bottomAnchor).isActive = true
        } else {
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.backgroundColor = .background
            containerView.addSubview(segmentedControl)
            view.addSubview(containerView)
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: commandHeader.bottomAnchor),
                containerView.leadingAnchor.constraint(equalTo: sidebarTableView.trailingAnchor),
                containerView.widthAnchor.constraint(equalTo: view.widthAnchor),
                containerView.heightAnchor.constraint(equalToConstant: 56),
                segmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor),
                segmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                segmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                containerView.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
                tableView.topAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        self.segmentedControl = segmentedControl

        performQuery()

        // request an initial location on the list screen, because it can take quite a few seconds, so that
        // an accurate location is ready hopefully by the time the user needs one...
        LocationHelper.instance.requestLocation()
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

    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Event>>) {
        switch changes {
        case .initial:
            tableView.reloadData()
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

    @objc func performQuery() {
        notificationToken?.invalidate()

        let realm = AppRealm.open()
        results = realm.objects(Event.self)
        if let text = commandHeader.searchField.text, !text.isEmpty {
            results = results?.filter("name CONTAINS[cd] %@", text)
        }
        if segmentedControl.selectedIndex == 0 {
            results = results?.filter("end >= %@", Date())
            results = results?.sorted(by: [
                SortDescriptor(keyPath: "start", ascending: true),
                SortDescriptor(keyPath: "end", ascending: true),
                SortDescriptor(keyPath: "name", ascending: true)
            ])
        } else {
            results = results?.filter("end < %@", Date())
            results = results?.sorted(by: [
                SortDescriptor(keyPath: "start", ascending: false),
                SortDescriptor(keyPath: "end", ascending: false),
                SortDescriptor(keyPath: "name", ascending: true)
            ])
        }
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
        refresh()
    }

    @objc func refresh() {
        tableView.refreshControl?.beginRefreshing()
        AppRealm.getEvents(filter: segmentedControl.selectedIndex == 1 ? "past" : "current", search: commandHeader.searchField.text) { [weak self] (nextUrl, error) in
            self?.handleResponse(nextUrl: nextUrl, error: error)
        }
    }

    func handleResponse(nextUrl: String?, error: Error?) {
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

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        performQuery()
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == tableView && scrollView.contentOffset.y >= scrollView.contentSize.height / 2 {
            if let nextUrl = nextUrl {
                self.nextUrl = nil
                AppRealm.getNextEvents(url: nextUrl) { [weak self] (nextUrl, error) in
                    self?.handleResponse(nextUrl: nextUrl, error: error)
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == sidebarTableView {
            return 3
        }
        return results?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == sidebarTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SidebarItem", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Sidebar.item.switch".localized
            case 1:
                cell.textLabel?.text = "Sidebar.item.incidents".localized
            case 2:
                cell.textLabel?.text = "Sidebar.item.logOut".localized
            default:
                break
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath)
        if let cell = cell as? EventTableViewCell, let event = results?[indexPath.row] {
            cell.update(from: event)
        }
        return cell
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
                let vc = IncidentsViewController()
                for window in UIApplication.shared.windows where window.isKeyWindow {
                    window.rootViewController = vc
                    break
                }
                break
            case 2:
                logout()
            default:
                break
            }
            return
        }
        if let event = results?[indexPath.row] {
            // no-op for now
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
