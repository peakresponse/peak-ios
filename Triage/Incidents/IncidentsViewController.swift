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

class IncidentsViewController: UIViewController, ActiveIncidentsViewDelegate, AssignmentViewControllerDelegate, CommandHeaderDelegate, PRKit.FormFieldDelegate,
                               UITableViewDataSource, UITableViewDelegate {
    weak var commandHeader: CommandHeader!
    weak var eventLabel: UILabel?
    weak var sidebarTableView: SidebarTableView!
    weak var sidebarTableViewLeadingConstraint: NSLayoutConstraint!
    weak var versionLabel: UILabel!
    weak var tableView: UITableView!
    weak var commandFooter: CommandFooter!
    weak var activeIncidentsView: ActiveIncidentsView!
    weak var activeIncidentsViewHeightConstraint: NSLayoutConstraint!
    weak var segmentedControl: SegmentedControl!

    var eventId: String?

    var notificationToken: NotificationToken?
    var results: Results<Incident>?
    var nextUrl: String?

    deinit {
        notificationToken?.invalidate()
        AppRealm.disconnectIncidents()
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
        tableView.register(IncidentTableViewCell.self, forCellReuseIdentifier: "Incident")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: sidebarTableView.trailingAnchor),
            tableView.widthAnchor.constraint(equalTo: view.widthAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.tableView = tableView

        var eventView: UIView?
        if let eventId = eventId, let event = AppRealm.open().object(ofType: Event.self, forPrimaryKey: eventId) {
            // start fetching event to get venue, region, and facilities, if any
            AppRealm.getEvent(id: eventId) { _ in
                DispatchQueue.main.async {
                    if let venue = event.venue, let region = venue.region, let routedUrl = region.routedUrl {
                        print("Event venue region routed url is", routedUrl)
                        REDRealm.disconnect()
                        REDRealm.deleteAll()
                        REDApiClient.shared = REDApiClient(baseURL: routedUrl)
                        REDRealm.connect(venue.id)
                    }
                }
            }

            eventView = UIView()
            eventView?.translatesAutoresizingMaskIntoConstraints = false
            eventView?.backgroundColor = .background
            view.addSubview(eventView!)
            NSLayoutConstraint.activate([
                eventView!.topAnchor.constraint(equalTo: commandHeader.bottomAnchor),
                eventView!.leadingAnchor.constraint(equalTo: sidebarTableView.trailingAnchor),
                eventView!.widthAnchor.constraint(equalTo: view.widthAnchor)
            ])

            let eventLabel = UILabel()
            eventLabel.translatesAutoresizingMaskIntoConstraints = false
            eventLabel.text = String(format: "IncidentsViewController.event".localized, event.name ?? "")
            eventLabel.textAlignment = .center
            eventLabel.lineBreakMode = .byTruncatingTail
            eventLabel.adjustsFontSizeToFitWidth = false
            eventLabel.font = .body14Bold
            eventLabel.textColor = .headingText
            eventView?.addSubview(eventLabel)
            NSLayoutConstraint.activate([
                eventLabel.topAnchor.constraint(equalTo: eventView!.topAnchor),
                eventLabel.leadingAnchor.constraint(equalTo: eventView!.leadingAnchor, constant: 20),
                eventLabel.trailingAnchor.constraint(equalTo: eventView!.trailingAnchor, constant: -20),
                eventView!.bottomAnchor.constraint(equalTo: eventLabel.bottomAnchor, constant: 8)
            ])
            self.eventLabel = eventLabel
        }

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
            tableView.topAnchor.constraint(equalTo: (eventView ?? commandHeader).bottomAnchor).isActive = true
        } else {
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.backgroundColor = .background
            containerView.addSubview(segmentedControl)
            view.addSubview(containerView)
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: (eventView ?? commandHeader).bottomAnchor),
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

        let commandFooter = CommandFooter()
        commandFooter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(commandFooter)
        NSLayoutConstraint.activate([
            commandFooter.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            commandFooter.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            commandFooter.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.commandFooter = commandFooter

        let newButton = PRKit.Button()
        newButton.translatesAutoresizingMaskIntoConstraints = false
        newButton.bundleImage = "Plus24px"
        newButton.style = .primary
        newButton.addTarget(self, action: #selector(newPressed(_:)), for: .touchUpInside)
        newButton.setTitle("Button.newIncident".localized, for: .normal)
        commandFooter.addSubview(newButton)

        let activeIncidentsView = ActiveIncidentsView()
        activeIncidentsView.translatesAutoresizingMaskIntoConstraints = false
        activeIncidentsView.delegate = self
        view.addSubview(activeIncidentsView)
        let activeIncidentsViewHeightConstraint = activeIncidentsView.heightAnchor.constraint(equalToConstant: 128)
        NSLayoutConstraint.activate([
            activeIncidentsViewHeightConstraint,
            activeIncidentsView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            activeIncidentsView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            activeIncidentsView.bottomAnchor.constraint(equalTo: commandFooter.topAnchor)
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
        contentInset.bottom = commandFooter.frame.height + activeIncidentsViewHeightConstraint.constant + 16
        tableView.contentInset = contentInset
        var scrollIndicatorInsets = tableView.scrollIndicatorInsets
        scrollIndicatorInsets.bottom = commandFooter.frame.height + activeIncidentsViewHeightConstraint.constant + 16
        tableView.scrollIndicatorInsets = scrollIndicatorInsets
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

    func toggleSidebar(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            if self?.sidebarTableViewLeadingConstraint.constant == 0 {
                self?.sidebarTableViewLeadingConstraint.constant = -300
            } else {
                self?.sidebarTableViewLeadingConstraint.constant = 0
            }
            self?.view.layoutIfNeeded()
        }, completion: completion)
    }

    @objc func newPressed(_ sender: PRKit.Button) {
        let vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Reports")
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
                AppSettings.eventId = nil
                let vc = EventsViewController()
                toggleSidebar { _ in
                    for window in UIApplication.shared.windows where window.isKeyWindow {
                        window.rootViewController = vc
                        break
                    }
                }
                break
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
