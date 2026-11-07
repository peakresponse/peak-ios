//
//  RespondersViewController.swift
//  Triage
//
//  Created by Francis Li on 2/23/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
internal import RealmSwift
import UIKit

class RespondersViewController: SceneViewController, ResponderViewControllerDelegate,
                                ResponderTableViewCellDelegate, RespondersCountsHeaderViewDelegate,
                                UITableViewDataSource, UITableViewDelegate {
    weak var respondersCountsHeaderView: RespondersCountsHeaderView!
    weak var tableView: UITableView!
    weak var addButton: PRKit.RoundButton!

    var scene: Scene?
    var results: Results<Responder>?
    var notificationToken: NotificationToken?

    var filter: String?
    var filteredResults: Results<Responder>?
    var filteredNotificationToken: NotificationToken?

    override init() {
        super.init()
        tabBarItem.title = "TabBarItem.stage".localized
        tabBarItem.image = UIImage(named: "Stage", in: PRKitBundle.instance, compatibleWith: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationToken?.invalidate()
        filteredNotificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

        let respondersCountsHeaderView = RespondersCountsHeaderView()
        respondersCountsHeaderView.translatesAutoresizingMaskIntoConstraints = false
        respondersCountsHeaderView.delegate = self
        contentView.addSubview(respondersCountsHeaderView)
        NSLayoutConstraint.activate([
            respondersCountsHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            respondersCountsHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            respondersCountsHeaderView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])
        self.respondersCountsHeaderView = respondersCountsHeaderView

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        let tableView = TableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .background
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.register(ResponderTableViewCell.self, forCellReuseIdentifier: "Responder")
        contentView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: respondersCountsHeaderView.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        self.tableView = tableView

        let addButton = RoundButton(frame: CGRect(x: 0, y: 0, width: 94, height: 94))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Button.addUnit".localized, for: .normal)
        addButton.addTarget(self, action: #selector(addPressed(_:)), for: .touchUpInside)
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 94),
            addButton.heightAnchor.constraint(equalToConstant: 94),
            addButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
        self.addButton = addButton

        var contentInset = tableView.contentInset
        contentInset.bottom += addButton.frame.height + 32
        tableView.contentInset = contentInset

        initSceneCommandHeader()

        performQuery()

        isEditing = scene?.isResponder(userId: AppSettings.userId) ?? false
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            addButton.isHidden = false
        } else {
            addButton.isHidden = true
        }
    }

    override func performQuery() {
        notificationToken?.invalidate()
        filteredNotificationToken?.invalidate()

        let realm = AppRealm.open()
        guard let sceneId = AppSettings.sceneId else { return }
        scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)

        guard let scene = scene else { return }
        results = scene.responders.filter("(user=%@ OR vehicle<>%@) AND departedAt=%@", NSNull(), NSNull(), NSNull())
        results = results?.sorted(by: [
            SortDescriptor(keyPath: "sort"),
            SortDescriptor(keyPath: "arrivedAt"),
            SortDescriptor(keyPath: "vehicle.number"),
            SortDescriptor(keyPath: "user.firstName"),
            SortDescriptor(keyPath: "user.lastName")
        ])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }

        filteredResults = results
        if let text = commandHeader.searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            filteredResults = filteredResults?.filter("(unitNumber CONTAINS[cd] %@) OR (vehicle.number CONTAINS[cd] %@) OR (user.firstName CONTAINS[cd] %@) OR (user.lastName CONTAINS[cd] %@)",
                                              text, text, text, text)
        }
        if let filter = filter {
            filteredResults = filteredResults?.filter(filter)
        }
        filteredNotificationToken = filteredResults?.observe { [weak self] (changes) in
            self?.didObserveFilteredRealmChanges(changes)
        }

        refresh()
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Responder>>) {
        switch changes {
        case .initial:
            fallthrough
        case .update:
            respondersCountsHeaderView.configure(from: results)
        case .error(let error):
            presentAlert(error: error)
        }
    }

    func didObserveFilteredRealmChanges(_ changes: RealmCollectionChange<Results<Responder>>) {
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

    @objc func refresh() {
        guard let sceneId = scene?.id else { return }
        tableView.refreshControl?.beginRefreshing()
        AppRealm.getResponders(sceneId: sceneId) { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                print(error)
            }
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
            }
        }
    }

    @objc func addPressed(_ sender: RoundButton) {
        let vc = ResponderViewController()
        vc.delegate = self
        let responder = Responder()
        responder.scene = scene
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized, style: .plain,
                                                              target: self, action: #selector(dismissAnimated))
        vc.responder = responder
        vc.isEditing = true
        presentAnimated(vc)
    }

    // MARK: - ResponderTableViewCellDelegate

    func responderTableViewCellDidMarkArrived(_ cell: ResponderTableViewCell, responderId: String?) {
        guard let responderId = responderId else { return }
        AppRealm.markResponderArrived(responderId: responderId) { _ in
        }
    }

    // MARK: - ResponderViewControllerDelegate

    func responderViewControllerDidSave(_ vc: ResponderViewController) {
        dismissAnimated()
    }

    // MARK: - RespondersCountsHeaderViewDelegate

    func respondersCountsHeaderView(_ view: RespondersCountsHeaderView, didPressArrived button: Button) {
        filter = "arrivedAt<>NULL"
        performQuery()
    }

    func respondersCountsHeaderView(_ view: RespondersCountsHeaderView, didPressEnroute button: Button) {
        filter = "arrivedAt=NULL"
        performQuery()
    }

    func respondersCountsHeaderView(_ view: RespondersCountsHeaderView, didPressTotal button: Button) {
        filter = nil
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Responder", for: indexPath)
        if let cell = cell as? ResponderTableViewCell {
            cell.delegate = self
            if indexPath.row < (filteredResults?.count ?? 0), let responder = filteredResults?[indexPath.row] {
                cell.configure(from: responder)
                cell.button.isEnabled = isEditing
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ResponderTableViewCell {
            cell.constrain(to: contentView)
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let responder = filteredResults?[indexPath.row] else { return }
        if isEditing && responder.user == nil && responder.vehicle == nil {
            let vc = ResponderViewController()
            if let responder = filteredResults?[indexPath.row] {
                vc.delegate = self
                vc.responder = responder
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized, style: .plain,
                                                                      target: self, action: #selector(dismissAnimated))
                vc.isEditing = true
            }
            presentAnimated(vc)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
