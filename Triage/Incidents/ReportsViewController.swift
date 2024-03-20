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
import AlignedCollectionViewFlowLayout

class ReportsViewController: SceneViewController, CommandHeaderDelegate, CustomTabBarDelegate, ReportsCountsHeaderViewDelegate,
                             UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var customTabBar: CustomTabBar!
    @IBOutlet weak var addButton: RoundButton!

    var incident: Incident?
    var isMCI = false
    var filterPriority: TriagePriority?
    var results: Results<Report>?
    var filteredResults: Results<Report>?
    var notificationToken: NotificationToken?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        tabBarItem.title = "TabBarItem.treat".localized
        tabBarItem.image = UIImage(named: "Treat", in: PRKitBundle.instance, compatibleWith: nil)
    }

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if incident == nil, let sceneId = AppSettings.sceneId,
           let scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId) {
            incident = scene.incident.first
            isMCI = scene.isMCI
        }

        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        if let layout = layout {
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.sectionHeadersPinToVisibleBounds = true
        }

        if isMCI {
            addButton.isHidden = false
            initSceneCommandHeader()
            collectionView.register(ReportsCountsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Counts")
        } else {
            addButton.isHidden = true
            commandHeader.isSearchHidden = true
            commandHeader.leftBarButtonItem = UIBarButtonItem(title: "Button.done".localized, style: .plain, target: self, action: #selector(dismissAnimated))
        }

        customTabBar.buttonTitle = "Button.addPatient".localized
        customTabBar.delegate = self
        customTabBar.isHidden = true

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        collectionView.register(ReportCollectionViewCell.self, forCellWithReuseIdentifier: "Report")

        if isMCI {
            var contentInset = collectionView.contentInset
            contentInset.bottom += addButton.frame.height
            collectionView.contentInset = contentInset
        }

        performQuery()

        if !isMCI, let incident = incident, incident.reportsCount == 0 {
            DispatchQueue.main.async { [weak self] in
                self?.presentNewReport(incident: incident, animated: false)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if incident == nil, isBeingPresented {
            presentNewReport(incident: nil, animated: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isMCI {
            var contentInset = collectionView.contentInset
            contentInset.bottom = customTabBar.frame.height
            collectionView.contentInset = contentInset
        }
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
            .filter("incident=%@ AND canonicalId=%@", incident, NSNull())
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

    @IBAction
    func addPressed(_ sender: RoundButton) {
        let vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Scan")
        if let vc = vc as? ScanViewController {
            vc.incident = incident
        }
        presentAnimated(vc)
    }

    @objc override func newReportCancelled() {
        view.isHidden = true
        dismiss(animated: true) { [weak self] in
            self?.dismiss(animated: false)
        }
    }

    // MARK: - CustomTabBarDelegate

    func customTabBar(_ tabBar: CustomTabBar, didSelect index: Int) {

    }

    func customTabBar(_ tabBar: CustomTabBar, didPress button: UIButton) {
        presentNewReport(incident: incident)
    }

    // MARK: - ReportContainerViewControllerDelegate

    override func reportContainerViewControllerDidSave(_ vc: ReportContainerViewController) {
        vc.commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized,
                                                             style: .done,
                                                             target: self,
                                                             action: #selector(self.dismissAnimated))
        incident = vc.incident
        if !isMCI {
            customTabBar.isHidden = false
        }
        performQuery()
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
        if let cell = cell as? ReportCollectionViewCell {
            cell.configure(report: filteredResults?[indexPath.row], index: indexPath.row)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Counts", for: indexPath)
        if let headerView = headerView as? ReportsCountsHeaderView {
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
            return CGSize(width: 372, height: 160)
        }
        return CGSize(width: view.frame.width, height: 160)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if isMCI {
            return CGSize(width: 0, height: 118)
        }
        return .zero
    }
}
