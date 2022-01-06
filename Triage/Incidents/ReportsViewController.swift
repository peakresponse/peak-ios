//
//  ReportsViewController.swift
//  Triage
//
//  Created by Francis Li on 1/4/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit
import PRKit
import RealmSwift

class ReportsViewController: UIViewController, CommandHeaderDelegate,
                             UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var collectionView: UICollectionView!

    var incident: Incident?
    var results: Results<Report>?
    var notificationToken: NotificationToken?
    var firstRefresh = true

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "Button.done".localized, style: .done, target:
                                                            self, action: #selector(dismissAnimated))

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        collectionView.register(ReportCollectionViewCell.self, forCellWithReuseIdentifier: "Report")

        performQuery()
    }

    @objc func performQuery() {
        guard let incident = incident else { return }

        notificationToken?.invalidate()

        let realm = AppRealm.open()
        results = realm.objects(Report.self)
            .filter("incident=%@", incident)
            .sorted(by: [SortDescriptor(keyPath: "createdAt", ascending: true)])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
        refresh()
    }

    @objc func refresh() {
        guard let incident = incident else { return }
        collectionView.refreshControl?.beginRefreshing()
        AppRealm.getReports(incident: incident) { [weak self] (results, error) in
            guard let self = self else { return }
            if let error = error {
                print(error)
            }
            if self.firstRefresh {
                self.firstRefresh = false
                // show add patient button footer
                if let results = results, results.count == 0 {
                    self.presentNewReport(animated: false) { [weak self] in
                        self?.collectionView.refreshControl?.endRefreshing()
                    }
                    return
                }
            }
            self.collectionView.refreshControl?.endRefreshing()
        }
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Report>>) {
        switch changes {
        case .initial:
            collectionView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: insertions.map { IndexPath(row: $0, section: 0) })
                self.collectionView.deleteItems(at: deletions.map { IndexPath(row: $0, section: 0) })
                self.collectionView.reloadItems(at: modifications.map { IndexPath(row: $0, section: 0) })
            }, completion: nil)
        case .error(let error):
            presentAlert(error: error)
        }
    }

    func presentNewReport(animated: Bool = true, completion: (() -> Void)? = nil) {
        let report = Report.newRecord()
        report.incident = incident
        report.scene = incident?.scene
        report.response?.incidentNumber = incident?.number
        let realm = AppRealm.open()
        if let assignmentId = AppSettings.assignmentId,
           let assignment = realm.object(ofType: Assignment.self, forPrimaryKey: assignmentId) {
            if let dispatch = incident?.dispatches.first(where: { $0.vehicleId == assignment.vehicleId }) {
                report.time?.unitNotifiedByDispatch = dispatch.dispatchedAt
            }
            if let vehicleId = assignment.vehicleId, let vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId) {
                report.response?.unitNumber = vehicle.number
            }
        }
        presentReport(report: report, animated: animated, completion: completion)
    }

    func presentReport(report: Report, animated: Bool = true, completion: (() -> Void)? = nil) {
        let vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Incident")
        if let vc = vc as? IncidentViewController {
            vc.incident = incident
            vc.report = report
        }
        present(vc, animated: animated) { [weak self] in
            guard let self = self else { return }
            if let vc = vc as? IncidentViewController {
                if report.realm == nil {
                    vc.commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized,
                                                                         style: .plain,
                                                                         target: self,
                                                                         action: #selector(self.newReportCancelled))
                } else {
                    vc.commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized,
                                                                         style: .done,
                                                                         target: self,
                                                                         action: #selector(self.dismissAnimated))
                }
            }
            completion?()
        }
    }

    @objc func newReportCancelled() {
        view.isHidden = true
        dismiss(animated: true) { [weak self] in
            self?.dismiss(animated: false)
        }
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Report", for: indexPath)
        if let cell = cell as? ReportCollectionViewCell {
            cell.configure(report: results?[indexPath.row])
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let report = results?[indexPath.row] {
            presentReport(report: report, animated: true) {
                collectionView.deselectItem(at: indexPath, animated: false)
            }
        }
    }
}
