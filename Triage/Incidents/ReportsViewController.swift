//
//  ReportsViewController.swift
//  Triage
//
//  Created by Francis Li on 1/4/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit
import PRKit
internal import RealmSwift

class ReportsViewController: SceneViewController, ReportsCountsHeaderViewDelegate,
                             UITableViewDataSource, UITableViewDelegate {
    weak var reportsCountsHeaderView: ReportsCountsHeaderView?
    weak var tableView: UITableView!
    weak var addButton: RoundButton!

    var incident: Incident?
    var scene: Scene?
    var isMCI = false
    var filterPriority: TriagePriority?
    var results: Results<Report>?
    var filteredResults: Results<Report>?
    var notificationToken: NotificationToken?

    override init() {
        super.init()
        tabBarItem.title = "TabBarItem.treat".localized
        tabBarItem.image = UIImage(named: "Treat", in: PRKitBundle.instance, compatibleWith: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if incident == nil, let sceneId = AppSettings.sceneId {
            scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId)
            incident = scene?.incident.first
            isMCI = scene?.isMCI ?? false
        }

        view.backgroundColor = .background

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
            commandHeader.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            headerView.bottomAnchor.constraint(equalTo: commandHeader.bottomAnchor)
        ])
        self.commandHeader = commandHeader

        if isMCI {
            let reportsCountsHeaderView = ReportsCountsHeaderView()
            reportsCountsHeaderView.translatesAutoresizingMaskIntoConstraints = false
            reportsCountsHeaderView.delegate = self
            contentView.addSubview(reportsCountsHeaderView)
            NSLayoutConstraint.activate([
                reportsCountsHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor),
                reportsCountsHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                reportsCountsHeaderView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
            ])
            self.reportsCountsHeaderView = reportsCountsHeaderView
        }

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        let tableView = TableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .background
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.register(ReportTableViewCell.self, forCellReuseIdentifier: "Report")
        contentView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: isMCI ? reportsCountsHeaderView!.bottomAnchor : contentView.topAnchor),
            tableView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        self.tableView = tableView

        let addButton = RoundButton(frame: CGRect(x: 0, y: 0, width: 94, height: 94))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Button.addPatient".localized, for: .normal)
        addButton.addTarget(self, action: #selector(addPressed(_:)), for: .touchUpInside)
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 94),
            addButton.heightAnchor.constraint(equalToConstant: 94),
            addButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
        self.addButton = addButton

        if isMCI {
            initSceneCommandHeader()
            if scene?.isResponder(userId: AppSettings.userId) ?? false {
                showAddButton()
            }
        } else {
            addButton.isHidden = true
            commandHeader.isSearchHidden = true
            commandHeader.leftBarButtonItem = UIBarButtonItem(title: "Button.done".localized, style: .plain,
                                                              target: self, action: #selector(dismissAnimated))
        }

        performQuery()

        if !isMCI {
            if let incident = incident, incident.reportsCount == 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.presentNewReport(incident: incident, animated: false)
                }
            } else if incident != nil {
                addButton.isHidden = false
            }
        }
    }

    func showAddButton() {
        addButton.isHidden = false
        var contentInset = tableView.contentInset
        contentInset.bottom = addButton.frame.height + 16
        tableView.contentInset = contentInset
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if incident == nil, isBeingPresented {
            presentNewReport(incident: nil, animated: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let tableHeaderView = tableView.tableHeaderView {
            let size = tableHeaderView.systemLayoutSizeFitting(CGSize(width: tableView.bounds.width,
                                                                      height: CGFloat.greatestFiniteMagnitude))
            tableHeaderView.frame.size.height = size.height
        }
    }

    @objc override func performQuery() {
        guard let incident = incident else { return }

        notificationToken?.invalidate()

        let realm = AppRealm.open()
        results = realm.objects(Report.self)
            .filter("incident=%@ AND canonicalId=%@ AND deletedAt=%@", incident, NSNull(), NSNull())
        filteredResults = results
        if isMCI {
            if let text = commandHeader.searchField.text, !text.isEmpty {
                filteredResults = filteredResults?.filter("(pin CONTAINS[cd] %@) OR (patient.firstName CONTAINS[cd] %@) OR (patient.lastName CONTAINS[cd] %@)",
                                          text, text, text)
            }
            if let filterPriority = filterPriority {
                if filterPriority == .transported {
                    filteredResults = filteredResults?.filter("filterPriority=%d", filterPriority.rawValue)
                } else {
                    filteredResults = filteredResults?.filter("patient.priority=%d", filterPriority.rawValue)
                }
            }
            filteredResults = filteredResults?.sorted(by: [
                SortDescriptor(keyPath: "filterPriority"),
                SortDescriptor(keyPath: "pin")
            ])
        } else {
            filteredResults = filteredResults?.sorted(by: [
                SortDescriptor(keyPath: "patient.canonicalId"),
                SortDescriptor(keyPath: "patient.parentId", ascending: false)
            ])
        }
        notificationToken = filteredResults?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
        refresh()
    }

    @objc func refresh() {
        guard let incident = incident else { return }
        tableView.refreshControl?.beginRefreshing()
        AppRealm.getReports(incident: incident) { [weak self] (_, error) in
            guard let self else { return }
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
            reportsCountsHeaderView?.configure(from: results)
        case .error(let error):
            presentAlert(error: error)
        }
    }

    @objc func addPressed(_ sender: RoundButton) {
        if isMCI {
            let vc = ScanViewController()
            vc.incident = incident
            presentAnimated(vc)
        } else {
            presentNewReport(incident: incident)
        }
    }

    @objc override func newReportCancelled() {
        if (results?.count ?? 0) > 0 {
            dismiss(animated: true)
        } else {
            view.isHidden = true
            presentingViewController?.dismiss(animated: true)
        }
    }

    // MARK: - ReportContainerViewControllerDelegate

    override func reportContainerViewControllerDidSave(_ vc: ReportContainerViewController) {
        vc.commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized,
                                                             style: .done,
                                                             target: self,
                                                             action: #selector(self.dismissAnimated))
        incident = vc.incident
        if !isMCI {
            showAddButton()
        }
        performQuery()
    }

    // MARK: - ReportsCountsHeaderViewDelegate

    func reportsCountsHeaderView(_ view: ReportsCountsHeaderView, didSelect priority: TriagePriority?) {
        filterPriority = priority
        performQuery()
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
        if let cell = cell as? ReportTableViewCell {
            cell.configure(report: filteredResults?[indexPath.row], index: indexPath.row, selected: false)
            cell.checkbox.isHidden = true
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ReportTableViewCell {
            cell.constrain(to: contentView)
        }
    }

    // MARK: - UITableViewDelegete

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let report = filteredResults?[indexPath.row] {
            presentReport(report: report, animated: true) {
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
    }
}
