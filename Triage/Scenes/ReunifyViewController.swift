//
//  ReunifyViewController.swift
//  Triage
//
//  Created by Francis Li on 3/12/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
internal import RealmSwift
import UIKit

class ReunifyViewController: SceneViewController, ReportsCountsHeaderViewDelegate, ScanViewControllerDelegate,
                             UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    weak var reportsCountsHeaderView: ReportsCountsHeaderView!
    weak var collectionView: UICollectionView!
    weak var scanButton: RoundButton!

    var incident: Incident?
    var results: Results<Report>?
    var notificationToken: NotificationToken?

    var filterPriority: TriagePriority?
    var filteredResults: Results<Report>?
    var filteredNotificationToken: NotificationToken?

    override init() {
        super.init()
        tabBarItem.title = "TabBarItem.reunify".localized
        tabBarItem.image = UIImage(named: "Reunify", in: PRKitBundle.instance, compatibleWith: nil)
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

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 8

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .background
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.refreshControl = refreshControl
        collectionView.register(ReunifyCollectionViewCell.self, forCellWithReuseIdentifier: "Report")
        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: reportsCountsHeaderView.bottomAnchor),
            collectionView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        self.collectionView = collectionView

        let scanButton = RoundButton(frame: CGRect(x: 0, y: 0, width: 94, height: 94))
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.setTitle("Button.scanTag".localized, for: .normal)
        scanButton.addTarget(self, action: #selector(scanPressed(_:)), for: .touchUpInside)
        view.addSubview(scanButton)
        NSLayoutConstraint.activate([
            scanButton.widthAnchor.constraint(equalToConstant: 94),
            scanButton.heightAnchor.constraint(equalToConstant: 94),
            scanButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            scanButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
        self.scanButton = scanButton

        var contentInset = collectionView.contentInset
        contentInset.bottom = scanButton.frame.height + 32
        collectionView.contentInset = contentInset

        if incident == nil, let sceneId = AppSettings.sceneId,
           let scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId) {
            incident = scene.incident.first
        }

        initSceneCommandHeader()

        performQuery()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    @objc override func performQuery() {
        guard let incident = incident else { return }

        notificationToken?.invalidate()
        filteredNotificationToken?.invalidate()

        let realm = AppRealm.open()
        results = realm.objects(Report.self)
            .filter("incident=%@ AND canonicalId=%@ AND deletedAt=%@ AND filterPriority=%d", incident, NSNull(), NSNull(), TriagePriority.transported.rawValue)
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }

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
        filteredNotificationToken = filteredResults?.observe { [weak self] (changes) in
            self?.didObserveFilteredRealmChanges(changes)
        }
        refresh()
    }

    @objc func refresh() {
        guard let incident = incident else { return }
        collectionView.refreshControl?.beginRefreshing()
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
            fallthrough
        case .update:
            reportsCountsHeaderView.configure(from: results)
        case .error(let error):
            presentAlert(error: error)
        }
    }

    func didObserveFilteredRealmChanges(_ changes: RealmCollectionChange<Results<Report>>) {
        switch changes {
        case .initial:
            collectionView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: deletions.map { IndexPath(row: $0, section: 0) })
                self.collectionView.insertItems(at: insertions.map { IndexPath(row: $0, section: 0) })
                self.collectionView.reloadItems(at: modifications.map { IndexPath(row: $0, section: 0) })
            }, completion: nil)
        case .error(let error):
            presentAlert(error: error)
        }
    }

    @objc func scanPressed(_ sender: RoundButton) {
        let vc = ScanViewController()
        vc.delegate = self
        presentAnimated(vc)
    }

    // MARK: - ReportsCountsHeaderViewDelegate

    func reportsCountsHeaderView(_ view: ReportsCountsHeaderView, didSelect priority: TriagePriority?) {
        filterPriority = priority
        performQuery()
    }

    // MARK: - ScanViewControllerDelegate

    func scanViewController(_ vc: ScanViewController, didScan pin: String, report: Report?) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            if let report = report {
                presentReport(report: report, animated: true)
            } else {
                self.presentAlert(title: "TransportReportsViewController.notFound.title".localized,
                                  message: String(format: "TransportReportsViewController.notFound.message".localized, pin))
            }
        }
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

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let report = filteredResults?[indexPath.row] {
            presentReport(report: report, animated: true) {
                collectionView.deselectItem(at: indexPath, animated: false)
            }
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        var insets: UIEdgeInsets = .zero
        insets.left = -collectionView.frame.origin.x
        insets.right = mainView.frame.size.width - contentView.frame.maxX
        return insets
    }
}
