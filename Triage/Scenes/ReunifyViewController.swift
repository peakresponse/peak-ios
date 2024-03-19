//
//  ReunifyViewController.swift
//  Triage
//
//  Created by Francis Li on 3/12/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import AlignedCollectionViewFlowLayout
import Foundation
import PRKit
import RealmSwift
import UIKit

class ReunifyViewController: SceneViewController, CommandHeaderDelegate, ReportsCountsHeaderViewDelegate,
                             UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!

    var incident: Incident?
    var results: Results<Report>?
    var filterPriority: TriagePriority?
    var filteredResults: Results<Report>?
    var notificationToken: NotificationToken?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        tabBarItem.title = "TabBarItem.reunify".localized
        tabBarItem.image = UIImage(named: "Reunify", in: PRKitBundle.instance, compatibleWith: nil)
    }

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if incident == nil, let sceneId = AppSettings.sceneId,
           let scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId) {
            incident = scene.incident.first
        }

        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        if let layout = layout {
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.sectionHeadersPinToVisibleBounds = true
        }

        initSceneCommandHeader()

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        collectionView.register(ReunifyCollectionViewCell.self, forCellWithReuseIdentifier: "Report")
        collectionView.register(ReportsCountsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Counts")

        performQuery()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if traitCollection.horizontalSizeClass == .regular {
            if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                var sectionInset = layout.sectionInset
                let inset = max(0, (collectionView.frame.width - 744) / 2)
                sectionInset.left = inset
                sectionInset.right = inset
                layout.sectionInset = sectionInset
            }
        }
    }

    @objc override func performQuery() {
        guard let incident = incident else { return }

        notificationToken?.invalidate()

        let realm = AppRealm.open()
        results = realm.objects(Report.self)
            .filter("incident=%@ AND canonicalId=%@ AND filterPriority=%d", incident, NSNull(), TriagePriority.transported.rawValue)
        filteredResults = results
        if let text = commandHeader.searchField.text, !text.isEmpty {
            filteredResults = filteredResults?.filter("(pin CONTAINS[cd] %@) OR (patient.firstName CONTAINS[cd] %@) OR (patient.lastName CONTAINS[cd] %@)",
                                                      text, text, text)
        }
        if let filterPriority = filterPriority {
            filteredResults = filteredResults?.filter("patient.priority=%d", filterPriority.rawValue)
        }
        filteredResults = filteredResults?.sorted(by: [
            SortDescriptor(keyPath: "updatedAt", ascending: false)
        ])
        notificationToken = filteredResults?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
        refresh()
    }

    @objc func refresh() {
        guard let incident = incident else { return }
        collectionView.refreshControl?.beginRefreshing()
        collectionView.setContentOffset(CGPoint(x: 0, y: -(collectionView.refreshControl?.frame.size.height ?? 0)), animated: true)
        AppRealm.getReports(incident: incident) { [weak self] (_, error) in
            guard let self = self else { return }
            if let error = error {
                print(error)
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
            if let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: 0)) as? ReportsCountsHeaderView {
                headerView.configure(from: results)
            }
        case .error(let error):
            presentAlert(error: error)
        }
    }

    // MARK: - ReportsCountsHeaderViewDelegate

    func reportsCountsHeaderView(_ view: ReportsCountsHeaderView, didSelect priority: TriagePriority?) {
        filterPriority = priority
        performQuery()
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredResults?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Report", for: indexPath)
        if let cell = cell as? ReunifyCollectionViewCell {
            cell.configure(report: filteredResults?[indexPath.row], index: indexPath.row)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Counts", for: indexPath)
        if let headerView = headerView as? ReportsCountsHeaderView {
            headerView.countsView.arrangedSubviews.last?.isHidden = true
            headerView.delegate = self
            headerView.configure(from: results)
        }
        return headerView
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let report = filteredResults?[indexPath.row] {
            presentReport(report: report, animated: true) {
                collectionView.deselectItem(at: indexPath, animated: false)
            }
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if traitCollection.horizontalSizeClass == .regular {
            return CGSize(width: 372, height: 213)
        }
        return CGSize(width: view.frame.width, height: 213)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 0, height: 60)
    }
}
