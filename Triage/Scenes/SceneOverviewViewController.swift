//
//  SceneOverviewViewController.swift
//  Triage
//
//  Created by Francis Li on 5/29/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import AlignedCollectionViewFlowLayout
import PRKit
internal import RealmSwift
import UIKit

class SceneOverviewViewController: BaseViewController, CommandHeaderDelegate, PRKit.FormFieldDelegate,
                                   UITableViewDataSource, UITableViewDelegate {
    weak var commandHeader: CommandHeader!
    weak var sceneOverviewHeaderView: SceneOverviewHeaderView!
    weak var tableView: UITableView!
    var formInputAccessoryView: UIView!

    var scene: Scene?
    var responders: [Responder]?

    override func viewDidLoad() {
        super.viewDidLoad()

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

        let sceneOverviewHeaderView = SceneOverviewHeaderView()
        sceneOverviewHeaderView.translatesAutoresizingMaskIntoConstraints = false
        sceneOverviewHeaderView.closeButton.addTarget(self, action: #selector(closePressed(_:)), for: .touchUpInside)
        sceneOverviewHeaderView.editButton.addTarget(self, action: #selector(editPressed(_:)), for: .touchUpInside)
        contentView.addSubview(sceneOverviewHeaderView)
        NSLayoutConstraint.activate([
            sceneOverviewHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            sceneOverviewHeaderView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            sceneOverviewHeaderView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            sceneOverviewHeaderView.containerView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            sceneOverviewHeaderView.containerView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])
        self.sceneOverviewHeaderView = sceneOverviewHeaderView

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        let tableView = TableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .background
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.register(ResponderRoleTableViewCell.self, forCellReuseIdentifier: "Responder")
        contentView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: sceneOverviewHeaderView.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        self.tableView = tableView

        commandHeader.leftBarButtonItem = navigationItem.leftBarButtonItem
        commandHeader.searchFieldDelegate = self

        formInputAccessoryView = FormInputAccessoryView(rootView: view)

        performQuery()
    }

    func performQuery() {
        let realm = AppRealm.open()
        guard let sceneId = AppSettings.sceneId else { return }
        scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)

        guard let scene = scene else { return }

        sceneOverviewHeaderView.configure(from: scene)

        var results = scene.responders.filter("user<>%@ AND departedAt=%@", NSNull(), NSNull())
        if let text = commandHeader.searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            results = results.filter("(vehicle.number CONTAINS[cd] %@) OR (user.firstName CONTAINS[cd] %@) OR (user.lastName CONTAINS[cd] %@)",
                                      text, text, text)
        }
        results = results.sorted(by: [
            SortDescriptor(keyPath: "vehicle.number"),
            SortDescriptor(keyPath: "user.firstName"),
            SortDescriptor(keyPath: "user.lastName")
        ])

        responders = Array(results)
        refresh()
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Responder>>) {
        switch changes {
        case .initial:
            tableView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            tableView.performBatchUpdates({
                self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 1) }, with: .automatic)
                self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 1) }, with: .automatic)
                self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 1) }, with: .automatic)
            }, completion: nil)
        case .error(let error):
            presentAlert(error: error)
        }
    }

    @objc func refresh() {
        tableView.refreshControl?.endRefreshing()
        tableView.reloadData()
    }

    private func leaveScene() {
        _ = AppDelegate.leaveScene()
    }

    @objc func closePressed(_ sender: Any) {
        guard let scene = scene else { return }
        let sceneId = scene.id
        if scene.isMgs(userId: AppSettings.userId) {
            let vc = ModalViewController()
            vc.isDismissedOnAction = false
            vc.messageText = "CloseSceneConfirmation.message".localized
            vc.addAction(UIAlertAction(title: "Button.close".localized, style: .destructive, handler: { [weak self] (_) in
                guard let self = self else { return }
                AppRealm.endScene(sceneId: sceneId) { [weak self] (error) in
                    DispatchQueue.main.async { [weak self] in
                        vc.dismissAnimated()
                        if let error = error {
                            self?.presentAlert(error: error)
                        } else {
                            self?.leaveScene()
                        }
                    }
                }
            }))
            vc.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel))
            presentAnimated(vc)
        } else {
            if scene.isResponder(userId: AppSettings.userId) {
                let vc = ModalViewController()
                vc.isDismissedOnAction = false
                vc.messageText = "LeaveSceneConfirmation.message".localized
                vc.addAction(UIAlertAction(title: "Button.leave".localized, style: .destructive, handler: { [weak self] (_) in
                    guard let self = self else { return }
                    AppRealm.leaveScene(sceneId: sceneId) { [weak self] (error) in
                        DispatchQueue.main.async { [weak self] in
                            vc.dismissAnimated()
                            if let error = error {
                                self?.presentAlert(error: error)
                            } else {
                                self?.leaveScene()
                            }
                        }
                    }
                }))
                vc.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel))
                presentAnimated(vc)
            } else {
                leaveScene()
            }
        }
    }

    @objc func editPressed(_ sender: Any) {
        guard let scene = scene else { return }
        let vc = LocationViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized,
                                                              style: .plain,
                                                              target: self,
                                                              action: #selector(dismissAnimated))
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "NavigationBar.save".localized,
                                                               style: .done,
                                                               target: self,
                                                               action: #selector(saveScenePressed))
        vc.scene = scene
        vc.newScene = Scene(clone: scene)
        _ = vc.view
        vc.isEditing = true
        presentAnimated(vc)
    }

    @objc func saveScenePressed() {
        if let vc = presentedViewController as? LocationViewController {
            if let scene = vc.newScene {
                AppRealm.updateScene(scene: scene)
            }
            dismissAnimated()
        }
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        if let field = component as? PRKit.FormField {
            if field == commandHeader.searchField {
                performQuery()
            } else {
                let roleValue = field.attributeValue as? String
                let role = ResponderRole(rawValue: roleValue ?? "")
                if let responder = field.source as? Responder {
                    AppRealm.assignResponder(responderId: responder.id, role: role)
                    for cell in tableView.visibleCells {
                        if let cell = cell as? ResponderRoleTableViewCell,
                           let responderId = cell.responderId,
                           let responder = responders?.first(where: { $0.id == responderId }) {
                            cell.configure(from: responder)
                        }
                    }
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return responders?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Responder", for: indexPath)
        if let cell = cell as? ResponderRoleTableViewCell {
            let responder = responders?[indexPath.row]
            cell.configure(from: responder)
            cell.roleSelector.delegate = self
            cell.roleSelector.inputAccessoryView = formInputAccessoryView
            cell.roleSelector.isEnabled = scene?.isResponder(userId: AppSettings.userId) ?? false
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ResponderRoleTableViewCell {
            cell.constrain(to: contentView)
        }
    }
}
