//
//  TransportRespondersViewController.swift
//  Triage
//
//  Created by Francis Li on 3/6/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
internal import RealmSwift
import UIKit

@objc protocol TransportRespondersViewControllerDelegate {
    @objc optional func transportRespondersViewController(_ vc: TransportRespondersViewController, didSelect responder: Responder?)
    @objc optional func transportRespondersViewController(_ vc: TransportRespondersViewController, didRemove report: Report?)
}

class TransportRespondersViewController: UIViewController, ResponderTableViewCellDelegate,
                                         TransportCartViewController, ResponderViewControllerDelegate, PRKit.FormFieldDelegate,
                                         UITableViewDataSource, UITableViewDelegate {
    weak var contentView: UIView!
    weak var stackView: UIStackView!
    weak var tableView: UITableView!
    weak var addButton: PRKit.RoundButton!

    var stackViewConstraints: [NSLayoutConstraint] = []

    weak var delegate: TransportRespondersViewControllerDelegate?

    var scene: Scene?
    var results: Results<Responder>?
    var roles: [ResponderRole] = []
    var notificationToken: NotificationToken?

    var cart: TransportCart?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 6
        view.addSubview(stackView)
        let stackViewLeftConstraint = stackView.leftAnchor.constraint(equalTo: view.leftAnchor)
        stackViewLeftConstraint.priority = .defaultHigh
        let stackViewRightConstraint = stackView.rightAnchor.constraint(equalTo: view.rightAnchor)
        stackViewRightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackViewLeftConstraint,
            stackViewRightConstraint
        ])
        self.stackView = stackView

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        let tableView = TableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .background
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.register(ResponderTableViewCell.self, forCellReuseIdentifier: "Responder")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: stackView.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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

        let realm = AppRealm.open()
        guard let sceneId = AppSettings.sceneId else { return }
        scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)

        isEditing = scene?.isResponder(userId: AppSettings.userId) ?? false
    }

    func constrain(to view: UIView) {
        NSLayoutConstraint.deactivate(stackViewConstraints)
        stackViewConstraints.removeAll()
        stackViewConstraints.append(contentsOf: [
            stackView.leftAnchor.constraint(equalTo: view.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        NSLayoutConstraint.activate(stackViewConstraints)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        addButton.isHidden = !editing
        for cell in tableView.visibleCells {
            if let cell = cell as? ResponderTableViewCell {
                cell.checkbox.isEnabled = editing
                cell.button.isEnabled = editing
            }
        }
    }

    func performQuery(_ searchText: String? = nil) {
        notificationToken?.invalidate()

        guard let scene = scene else { return }
        results = scene.responders.filter("(user=%@ OR vehicle<>%@) AND departedAt=%@", NSNull(), NSNull(), NSNull())
        if let searchText = searchText, !searchText.isEmpty {
            results = results?.filter("(unitNumber CONTAINS[cd] %@) OR (vehicle.number CONTAINS[cd] %@) OR (user.firstName CONTAINS[cd] %@) OR (user.lastName CONTAINS[cd] %@)",
                                      searchText, searchText, searchText, searchText)
        }
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
        refresh()
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Responder>>) {
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
        // force reload of all cells to update timestamps
        tableView.reloadData()
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
        responder.status = true
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized, style: .plain,
                                                              target: self, action: #selector(dismissAnimated))
        vc.responder = responder
        vc.isEditing = true
        presentAnimated(vc)
    }

    func updateCart() {
        guard let cart = cart, let stackView = stackView else { return }
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        if cart.reports.count > 0 {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.heightAnchor.constraint(equalToConstant: 6).isActive = true
            stackView.addArrangedSubview(view)
            for report in cart.reports {
                let field = TransportCartReportField()
                field.delegate = self
                field.configure(from: report)
                stackView.addArrangedSubview(field)
            }
        } else {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.heightAnchor.constraint(equalToConstant: 0).isActive = true
            stackView.addArrangedSubview(view)
        }
    }

    func didToggleItem(at indexPath: IndexPath) {
        guard isEditing else { return }
        var indexPaths: [IndexPath] = []
        if let responder = cart?.responder {
            if let index = results?.firstIndex(of: responder) {
                indexPaths.append(IndexPath(row: index, section: 0))
            }
        }
        if let responder = results?[indexPath.row] {
            delegate?.transportRespondersViewController?(self, didSelect: responder)
            indexPaths.append(indexPath)
        }
        for indexPath in indexPaths {
            if let cell = tableView.cellForRow(at: indexPath) as? ResponderTableViewCell {
                let responder = results?[indexPath.row]
                cell.configure(from: responder, isSelected: responder == cart?.responder)
            }
        }
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        performQuery()
    }

    func formFieldDidPress(_ field: FormField) {
        if let field = field as? TransportCartReportField {
            delegate?.transportRespondersViewController?(self, didRemove: field.report)
        }
    }

    // MARK: - ResponderViewControllerDelegate

    func responderViewControllerDidSave(_ vc: ResponderViewController) {
        dismissAnimated()
    }

    // MARK: - ResponderTableViewCellDelegate

    func responderTableViewCell(_ cell: ResponderTableViewCell, didToggle isSelected: Bool) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        didToggleItem(at: indexPath)
    }

    func responderTableViewCellDidMarkArrived(_ cell: ResponderTableViewCell, responderId: String?) {
        guard let responderId = responderId else { return }
        AppRealm.markResponderArrived(responderId: responderId) { _ in
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        didToggleItem(at: indexPath)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Responder", for: indexPath)
        if let cell = cell as? ResponderTableViewCell, indexPath.row < (results?.count ?? 0) {
            let responder = results?[indexPath.row]
            cell.delegate = self
            cell.isSelectable = true
            cell.configure(from: responder, isSelected: responder == cart?.responder)
            cell.checkbox.isEnabled = isEditing
            cell.button.isEnabled = isEditing
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if view.superview != nil, let cell = cell as? ResponderTableViewCell {
            cell.constrain(to: contentView)
        }
    }
}
