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

// swiftlint:disable:next type_body_length
class EventsViewController: BaseViewController, AssignmentViewControllerDelegate, CommandHeaderDelegate, PRKit.FormFieldDelegate,
                            UITableViewDataSource, UITableViewDelegate {
    weak var commandHeader: CommandHeader!
    weak var sidebarTableView: SidebarTableView!
    weak var versionLabel: UILabel!
    weak var tableView: UITableView!
    weak var segmentedControl: SegmentedControl!
    var headerConstraints: [NSLayoutConstraint] = []

    var isEventsOnly = false

    var notificationToken: NotificationToken?
    var results: Results<Event>?
    var nextUrl: String?

    deinit {
        notificationToken?.invalidate()
    }

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        headerView.backgroundColor = .background

        if let agencyId = AppSettings.agencyId, let agency = AppRealm.open().object(ofType: Agency.self, forPrimaryKey: agencyId) {
            isEventsOnly = agency.isEventsOnly ?? false
        }

        let commandHeader = CommandHeader()
        commandHeader.translatesAutoresizingMaskIntoConstraints = false
        commandHeader.preservesSuperviewLayoutMargins = true
        commandHeader.delegate = self
        commandHeader.searchFieldDelegate = self
        headerView.addSubview(commandHeader)
        NSLayoutConstraint.activate([
            commandHeader.topAnchor.constraint(equalTo: headerView.topAnchor),
            commandHeader.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            commandHeader.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            commandHeader.contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            commandHeader.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])
        self.commandHeader = commandHeader
        setCommandHeaderUser(userId: AppSettings.userId, assignmentId: AppSettings.assignmentId)

        let sidebarTableView = SidebarTableView()
        sidebarTableView.translatesAutoresizingMaskIntoConstraints = false
        sidebarTableView.delegate = self
        sidebarTableView.dataSource = self
        view.addSubview(sidebarTableView)
        var sidebarTableViewConstraints = [
            sidebarTableView.topAnchor.constraint(equalTo: commandHeader.bottomAnchor),
            sidebarTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        sidebarTableViewConstraints.append(contentsOf: sidebarTableView.layoutConstraints(in: view))
        NSLayoutConstraint.activate(sidebarTableViewConstraints)
        self.sidebarTableView = sidebarTableView

        let versionLabel = UILabel()
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.font = .body14Bold
        versionLabel.text = AppSettings.version
        versionLabel.textColor = .interactiveText
        view.addSubview(versionLabel)
        NSLayoutConstraint.activate([
            versionLabel.leftAnchor.constraint(equalTo: sidebarTableView.leftAnchor, constant: 20),
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
        mainView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: mainView.topAnchor),
            tableView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
        ])
        self.tableView = tableView

        let segmentedControl = SegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addSegment(title: "EventsViewController.current".localized)
        segmentedControl.addSegment(title: "EventsViewController.past".localized)
        segmentedControl.addTarget(self, action: #selector(performQuery), for: .valueChanged)
        self.segmentedControl = segmentedControl

        updateLayout()

        performQuery()

        // request an initial location on the list screen, because it can take quite a few seconds, so that
        // an accurate location is ready hopefully by the time the user needs one...
        LocationHelper.instance.requestLocation()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        updateLayout(for: newCollection)
//        tableView.visibleCells.forEach { ($0 as? IncidentTableViewCell)?.updateLayout(newCollection) }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
//        tableView.visibleCells.forEach { ($0 as? IncidentTableViewCell)?.resizeLayout(size) }
    }

    func updateLayout(for traitCollection: UITraitCollection? = nil) {
        let traitCollection = traitCollection ?? view.traitCollection

        segmentedControl.removeFromSuperview()
        NSLayoutConstraint.deactivate(headerConstraints)
        headerConstraints.removeAll()

        if traitCollection.horizontalSizeClass == .regular {
            commandHeader.contentView.insertArrangedSubview(segmentedControl, at: 1)
            commandHeader.contentView.distribution = .fill
            headerConstraints.append(contentsOf: [
                headerView.bottomAnchor.constraint(equalTo: commandHeader.bottomAnchor),
                segmentedControl.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.55),
                commandHeader.searchField.widthAnchor.constraint(equalTo: commandHeader.userButton.widthAnchor)
            ])
        } else {
            commandHeader.contentView.distribution = .fillEqually
            headerView.addSubview(segmentedControl)
            headerConstraints.append(contentsOf: [
                segmentedControl.topAnchor.constraint(equalTo: commandHeader.bottomAnchor),
                segmentedControl.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                segmentedControl.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                headerView.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8)
            ])
        }
        NSLayoutConstraint.activate(headerConstraints)
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

    // MARK: - AssignmentViewControllerDelegate

    func assignmentViewController(_ vc: AssignmentViewController, didCreate assignmentId: String) {
        setCommandHeaderUser(userId: AppSettings.userId, assignmentId: assignmentId)
        performQuery()
        dismissAnimated()
    }

    // MARK: - CommandHeaderDelegate

    func commandHeaderDidPressUser(_ header: CommandHeader) {
        sidebarTableView.toggle()
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
            return isEventsOnly ? 2 : 3
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
                if isEventsOnly {
                    fallthrough
                } else {
                    cell.textLabel?.text = "Sidebar.item.incidents".localized
                }
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
                let vc = AssignmentViewController()
                vc.delegate = self
                present(vc, animated: true) { [weak self] in
                    self?.sidebarTableView.toggle()
                }
            case 1:
                if isEventsOnly {
                    fallthrough
                } else {
                    AppSettings.eventId = nil
                    _ = AppDelegate.leaveScene()
                }
            case 2:
                logout()
            default:
                break
            }
            return
        }
        if let event = results?[indexPath.row] {
            AppSettings.eventId = event.id
            _ = AppDelegate.leaveScene()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
