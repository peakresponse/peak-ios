//
//  IncidentsViewController.swift
//  Triage
//
//  Created by Francis Li on 10/27/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
internal import RealmSwift
import UIKit

// swiftlint:disable:next type_body_length
class IncidentsViewController: BaseViewController, ActiveIncidentsViewDelegate, AssignmentViewControllerDelegate,
                               CommandHeaderDelegate, PRKit.FormFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    weak var commandHeader: CommandHeader!
    weak var eventLabel: UILabel?
    weak var sidebarTableView: SidebarTableView!
    weak var versionLabel: UILabel!
    weak var tableView: UITableView!
    weak var addButton: RoundButton!
    weak var activeIncidentsView: ActiveIncidentsView!
    weak var activeIncidentsViewHeightConstraint: NSLayoutConstraint!
    weak var segmentedControl: SegmentedControl!
    var headerConstraints: [NSLayoutConstraint] = []

    var eventId: String?

    var notificationToken: NotificationToken?
    var results: Results<Incident>?
    var nextUrl: String?

    deinit {
        notificationToken?.invalidate()
        AppRealm.disconnectIncidents()
    }

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        headerView.backgroundColor = .background

        let commandHeader = CommandHeader()
        commandHeader.translatesAutoresizingMaskIntoConstraints = false
        commandHeader.preservesSuperviewLayoutMargins = true
        commandHeader.delegate = self
        commandHeader.searchFieldDelegate = self
        headerView.addSubview(commandHeader)
        NSLayoutConstraint.activate([
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
        tableView.register(IncidentTableViewCell.self, forCellReuseIdentifier: "Incident")
        mainView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: mainView.topAnchor),
            tableView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
        ])
        self.tableView = tableView

        if let eventId = eventId, let event = AppRealm.open().object(ofType: Event.self, forPrimaryKey: eventId) {
            // start fetching event to get venue, region, and facilities, if any
            AppRealm.getEvent(id: eventId) { _ in
                DispatchQueue.main.async {
                    if let venue = event.venue, let region = venue.region, let routedUrl = region.routedUrl {
                        REDRealm.disconnect()
                        REDRealm.deleteAll()
                        REDApiClient.shared = REDApiClient(baseURL: routedUrl)
                        REDRealm.connect(venue.id)
                    }
                }
            }

            let eventLabel = UILabel()
            eventLabel.translatesAutoresizingMaskIntoConstraints = false
            eventLabel.text = String(format: "IncidentsViewController.event".localized, event.name ?? "")
            eventLabel.textAlignment = .center
            eventLabel.lineBreakMode = .byTruncatingTail
            eventLabel.adjustsFontSizeToFitWidth = false
            eventLabel.font = .body14Bold
            eventLabel.textColor = .headingText
            headerView.addSubview(eventLabel)
            NSLayoutConstraint.activate([
                eventLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                eventLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor)
            ])
            self.eventLabel = eventLabel
        } else if let routedUrl = AppSettings.routedUrl {
            REDRealm.disconnect()
            REDRealm.deleteAll()
            REDApiClient.shared = REDApiClient(baseURL: routedUrl)
            REDRealm.connect()
        }

        let segmentedControl = SegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addSegment(title: "IncidentsViewController.mine".localized)
        segmentedControl.addSegment(title: "IncidentsViewController.all".localized)
        segmentedControl.addTarget(self, action: #selector(performQuery), for: .valueChanged)
        self.segmentedControl = segmentedControl

        updateLayout()

        let addButton = RoundButton(frame: CGRect(x: 0, y: 0, width: 94, height: 94))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Button.newIncident".localized, for: .normal)
        addButton.addTarget(self, action: #selector(newPressed(_:)), for: .touchUpInside)
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 94),
            addButton.heightAnchor.constraint(equalToConstant: 94),
            addButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])
        self.addButton = addButton

        let activeIncidentsView = ActiveIncidentsView()
        activeIncidentsView.translatesAutoresizingMaskIntoConstraints = false
        activeIncidentsView.delegate = self
        view.addSubview(activeIncidentsView)
        let activeIncidentsViewHeightConstraint = activeIncidentsView.heightAnchor.constraint(equalToConstant: 128)
        NSLayoutConstraint.activate([
            activeIncidentsViewHeightConstraint,
            activeIncidentsView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            activeIncidentsView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            activeIncidentsView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.activeIncidentsView = activeIncidentsView
        self.activeIncidentsViewHeightConstraint = activeIncidentsViewHeightConstraint

        performQuery()

        AppRealm.connectIncidents()

        // request an initial location on the list screen, because it can take quite a few seconds, so that
        // an accurate location is ready hopefully by the time the user needs one...
        LocationHelper.instance.requestLocation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var contentInset = tableView.contentInset
        contentInset.bottom = activeIncidentsViewHeightConstraint.constant + 16
        tableView.contentInset = contentInset
        var scrollIndicatorInsets = tableView.scrollIndicatorInsets
        scrollIndicatorInsets.bottom = activeIncidentsViewHeightConstraint.constant + 16
        tableView.scrollIndicatorInsets = scrollIndicatorInsets
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        updateLayout(for: newCollection)
        tableView.visibleCells.forEach { ($0 as? IncidentTableViewCell)?.updateLayout(newCollection) }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.visibleCells.forEach { ($0 as? IncidentTableViewCell)?.resizeLayout(size) }
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
                segmentedControl.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.55),
                commandHeader.searchField.widthAnchor.constraint(equalTo: commandHeader.userButton.widthAnchor)
            ])
            if let eventLabel {
                headerConstraints.append(contentsOf: [
                    eventLabel.topAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.topAnchor, constant: 16),
                    commandHeader.topAnchor.constraint(equalTo: eventLabel.bottomAnchor, constant: -8),
                    headerView.bottomAnchor.constraint(equalTo: commandHeader.bottomAnchor)
                ])
            } else {
                headerConstraints.append(contentsOf: [
                    commandHeader.topAnchor.constraint(equalTo: headerView.topAnchor),
                    headerView.bottomAnchor.constraint(equalTo: commandHeader.bottomAnchor)
                ])
            }
        } else {
            commandHeader.contentView.distribution = .fillEqually
            headerView.addSubview(segmentedControl)
            headerConstraints.append(contentsOf: [
                commandHeader.topAnchor.constraint(equalTo: headerView.topAnchor),
                segmentedControl.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                segmentedControl.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                headerView.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8)
            ])
            if let eventLabel {
                headerConstraints.append(contentsOf: [
                    eventLabel.topAnchor.constraint(equalTo: commandHeader.bottomAnchor),
                    segmentedControl.topAnchor.constraint(equalTo: eventLabel.bottomAnchor, constant: 8)
                ])
            } else {
                headerConstraints.append(contentsOf: [
                    segmentedControl.topAnchor.constraint(equalTo: commandHeader.bottomAnchor)
                ])
            }
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

    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Incident>>) {
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
        results = realm.objects(Incident.self)
            .sorted(by: [
                SortDescriptor(keyPath: "sort", ascending: false),
                SortDescriptor(keyPath: "createdAt", ascending: false)
            ])
        if let eventId = eventId {
            results = results?.filter("eventId=%@", eventId)
            if segmentedControl.selectedIndex == 0, let userId = AppSettings.userId {
                results = results?.filter("createdById=%@", userId)
            }
        } else {
            if let vehicleId = AppSettings.vehicleId {
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
        AppRealm.getIncidents(vehicleId: vehicleId, eventId: eventId, search: commandHeader.searchField.text,
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

    @objc func newPressed(_ sender: PRKit.Button) {
        let vc = ReportsViewController()
        presentAnimated(vc)
    }

    // MARK: - ActiveIncidentsViewDelegate

    func activeIncidentsView(_ view: ActiveIncidentsView, didChangeHeight height: CGFloat) {
        activeIncidentsViewHeightConstraint.constant = height
    }

    func activeIncidentsView(_ view: ActiveIncidentsView, didSelectIncident incident: Incident) {
        incidentPressed(incident)
    }

    func activeIncidentsViewDidSelectAll(_ view: ActiveIncidentsView) {
        let vc = ActiveIncidentsViewController()
        vc.modalPresentationStyle = .fullScreen
        presentAnimated(vc)
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
                AppRealm.getNextIncidents(url: nextUrl) { [weak self] (nextUrl, error) in
                    self?.handleIncidentsResponse(nextUrl: nextUrl, error: error)
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
                cell.textLabel?.text = "Sidebar.item.events".localized
            case 2:
                cell.textLabel?.text = "Sidebar.item.logOut".localized
            default:
                break
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Incident", for: indexPath)
        if let cell = cell as? IncidentTableViewCell, let incident = results?[indexPath.row] {
            cell.update(from: incident)
            cell.updateLayout()
            cell.resizeLayout()
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
                AppSettings.eventId = nil
                sidebarTableView.toggle { _ in
                    AppDelegate.enterEvents()
                }
            case 2:
                logout()
            default:
                break
            }
            return
        }
        if let incident = results?[indexPath.row] {
            incidentPressed(incident)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
