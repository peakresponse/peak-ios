//
//  ActiveIncidentsView.swift
//  Triage
//
//  Created by Francis Li on 9/27/23.
//  Copyright © 2023 Francis Li. All rights reserved.
//

import UIKit
import RealmSwift

@objc protocol ActiveIncidentsViewDelegate: AnyObject {
    @objc func activeIncidentsView(_ view: ActiveIncidentsView, didChangeHeight height: CGFloat)
    @objc func activeIncidentsView(_ view: ActiveIncidentsView, didSelectIncident incident: Incident)
    @objc func activeIncidentsViewDidSelectAll(_ view: ActiveIncidentsView)
}

private class ActiveIncidentsTableView: UITableView {
    weak var activeIncidentsView: ActiveIncidentsView?
    override var contentSize: CGSize {
        didSet { activeIncidentsView?.dispatchHeight() }
    }
}

class ActiveIncidentsView: UIView, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var delegate: ActiveIncidentsViewDelegate?
    weak var headerView: UIView!
    fileprivate var tableView: ActiveIncidentsTableView!

    var notificationToken: NotificationToken?
    var results: Results<Incident>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        notificationToken?.invalidate()
    }

    private func commonInit() {
        addShadow(withOffset: CGSize(width: 4, height: -4), radius: 20, color: .dropShadow, opacity: 0.4)

        backgroundColor = .brandSecondary800
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)
        let headerHeightContstraint = headerView.heightAnchor.constraint(equalToConstant: 24)
        headerHeightContstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leftAnchor.constraint(equalTo: leftAnchor),
            headerView.rightAnchor.constraint(equalTo: rightAnchor),
            headerHeightContstraint
        ])
        self.headerView = headerView

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            label.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 20),
            label.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: 20)
        ])
        label.text = "ActiveIncidentsView.header".localized
        label.font = .body14Bold
        label.textColor = .white

        tableView = ActiveIncidentsTableView(frame: .zero, style: .plain)
        tableView.isScrollEnabled = false
        tableView.activeIncidentsView = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(IncidentTableViewCell.self, forCellReuseIdentifier: "Incident")
        tableView.register(ListItemTableViewCell.self, forCellReuseIdentifier: "Item")
        tableView.dataSource = self
        tableView.delegate = self
        addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: leftAnchor),
            tableView.rightAnchor.constraint(equalTo: rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        performQuery()
    }

    private func performQuery() {
        notificationToken?.invalidate()
        let realm = AppRealm.open()
        results = realm.objects(Incident.self)
            .sorted(by: [
                SortDescriptor(keyPath: "createdAt", ascending: false),
                SortDescriptor(keyPath: "sort", ascending: false),
                SortDescriptor(keyPath: "number", ascending: false)
            ])
            .filter("scene.isMCI=%@ AND scene.isActive=%@", true, true)
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
    }

    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Incident>>) {
        switch changes {
        case .initial:
            fallthrough
        case .update:
            tableView.reloadData()
        case .error(let error):
            // presentAlert(error: error)
            print(error)
            break
        }
    }

    fileprivate func dispatchHeight() {
        var height = tableView.contentSize.height
        if height > 0 {
            headerView.isHidden = false
            height += headerView.frame.height
        } else {
            headerView.isHidden = true
        }
        delegate?.activeIncidentsView(self, didChangeHeight: height)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = results?.count ?? 0
        if count > 1 {
            return 2
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if indexPath.row > 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath)
            if let cell = cell as? ListItemTableViewCell {
                let count = results?.count ?? 0
                cell.label.text = String(format: "ActiveIncidentsView.viewAll".localized, count)
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "Incident", for: indexPath)
            if let cell = cell as? IncidentTableViewCell, let incident = results?[indexPath.row] {
                cell.update(from: incident)
            }
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row > 0 {
            delegate?.activeIncidentsViewDidSelectAll(self)
        } else {
            if let incident = results?[indexPath.row] {
                delegate?.activeIncidentsView(self, didSelectIncident: incident)
            }
        }
    }
}
