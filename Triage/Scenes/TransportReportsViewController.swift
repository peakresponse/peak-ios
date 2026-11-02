//
//  TransportReportsViewController.swift
//  Triage
//
//  Created by Francis Li on 3/6/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
internal import RealmSwift
import UIKit

@objc protocol TransportReportsViewControllerDelegate {
    @objc optional func transportReportsViewController(_ vc: TransportReportsViewController, didSelect report: Report?)
}

class TransportReportsViewController: UIViewController, TransportCartViewController, PRKit.FormFieldDelegate, ScanViewControllerDelegate,
                                      UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addButton: RoundButton!

    weak var delegate: TransportReportsViewControllerDelegate?
    var cart: TransportCart?

    var incident: Incident?
    var results: Results<Report>?
    var filteredResults: Results<Report>?
    var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .background
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.refreshControl = refreshControl
        collectionView.register(TransportReportCollectionViewCell.self, forCellWithReuseIdentifier: "Report")
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.collectionView = collectionView

        let addButton = RoundButton(frame: CGRect(x: 0, y: 0, width: 94, height: 94))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Button.scanTag".localized, for: .normal)
        addButton.addTarget(self, action: #selector(addPressed(_:)), for: .touchUpInside)
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 94),
            addButton.heightAnchor.constraint(equalToConstant: 94),
            addButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])
        self.addButton = addButton

        isEditing = incident?.scene?.isResponder(userId: AppSettings.userId) ?? false
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        addButton.isHidden = !isEditing
        for cell in collectionView.visibleCells {
            if let cell = cell as? TransportReportCollectionViewCell {
                cell.checkbox.isEnabled = isEditing
                cell.checkbox.isUserInteractionEnabled = false
            }
        }
    }

    @objc func performQuery(_ searchText: String? = nil) {
        guard let incident = incident else { return }

        notificationToken?.invalidate()

        let realm = AppRealm.open()
        results = realm.objects(Report.self)
            .filter("incident=%@ AND canonicalId=%@ AND deletedAt=%@", incident, NSNull(), NSNull())
        filteredResults = results
        if let searchText = searchText, !searchText.isEmpty {
            filteredResults = filteredResults?.filter("(pin CONTAINS[cd] %@) OR (patient.firstName CONTAINS[cd] %@) OR (patient.lastName CONTAINS[cd] %@)",
                                                      searchText, searchText, searchText)
        }
        filteredResults = filteredResults?.sorted(by: [
            SortDescriptor(keyPath: "filterPriority"),
            SortDescriptor(keyPath: "updatedAt")
        ])
        notificationToken = filteredResults?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
        refresh()
    }

    @objc func refresh() {
        guard let incident = incident else { return }
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
                self.collectionView.deleteItems(at: deletions.map { IndexPath(row: $0, section: 0) })
                self.collectionView.insertItems(at: insertions.map { IndexPath(row: $0, section: 0) })
                self.collectionView.reloadItems(at: modifications.map { IndexPath(row: $0, section: 0) })
            }, completion: nil)
        case .error(let error):
            presentAlert(error: error)
        }
    }

    @IBAction
    func addPressed(_ sender: RoundButton) {
        let vc = ScanViewController()
        vc.delegate = self
        presentAnimated(vc)
    }

    func updateCart() {

    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        performQuery()
    }

    func formFieldShouldReturn(_ field: PRKit.FormField) -> Bool {
        field.resignFirstResponder()
        return false
    }

    // MARK: - ScanViewControllerDelegate

    func scanViewController(_ vc: ScanViewController, didScan pin: String, report: Report?) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            if let report = report {
                self.delegate?.transportReportsViewController?(self, didSelect: report)
                if let index = filteredResults?.firstIndex(of: report) {
                    let indexPath = IndexPath(row: index, section: 0)
                    collectionView.reloadItems(at: [indexPath])
                    collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
                }
            } else {
                self.presentAlert(title: "TransportReportsViewController.notFound.title".localized, message: String(format: "TransportReportsViewController.notFound.message".localized, pin))
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
        if let cell = cell as? TransportReportCollectionViewCell, let report = filteredResults?[indexPath.row] {
            cell.configure(report: report, index: indexPath.row, selected: cart?.reports.contains(report) ?? false)
            cell.checkbox.isEnabled = isEditing
            cell.checkbox.isUserInteractionEnabled = false
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if isEditing, let report = filteredResults?[indexPath.row] {
            delegate?.transportReportsViewController?(self, didSelect: report)
            if let cell = collectionView.cellForItem(at: indexPath) as? TransportReportCollectionViewCell {
                cell.configure(report: report, index: indexPath.row, selected: cart?.reports.contains(report) ?? false)
            }
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if traitCollection.horizontalSizeClass == .regular {
            return CGSize(width: 372, height: 125)
        }
        return CGSize(width: view.frame.width, height: 125)
    }
}
