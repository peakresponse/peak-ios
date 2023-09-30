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
        addShadow(withOffset: CGSize(width: 4, height: -4), radius: 20, color: .base800, opacity: 0.4)

        backgroundColor = .brandSecondary800
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leftAnchor.constraint(equalTo: leftAnchor),
            headerView.rightAnchor.constraint(equalTo: rightAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 24)
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
            // presentAlert(error: error)
            print(error)
            break
        }
    }

    fileprivate func dispatchHeight() {
        var height = tableView.contentSize.height
        if height > 0 {
            height += headerView.frame.height
        }
        delegate?.activeIncidentsView(self, didChangeHeight: height)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(1, results?.count ?? 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Incident", for: indexPath)
        if let cell = cell as? IncidentTableViewCell, let incident = results?[indexPath.row] {
            cell.update(from: incident)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let incident = results?[indexPath.row] {
            delegate?.activeIncidentsView(self, didSelectIncident: incident)
        }
    }
}