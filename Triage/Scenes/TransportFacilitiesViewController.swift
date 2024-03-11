//
//  TransportFacilitiesViewController.swift
//  Triage
//
//  Created by Francis Li on 3/6/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import AlignedCollectionViewFlowLayout
import Foundation
import PRKit
import RealmSwift
import UIKit

@objc protocol TransportFacilitiesViewControllerDelegate {
    @objc optional func transportFacilitiesViewController(_ vc: TransportFacilitiesViewController, didRemoveReport report: Report?)
    @objc optional func transportFacilitiesViewController(_ vc: TransportFacilitiesViewController, didRemoveResponder responder: Responder?)
    @objc optional func transportFacilitiesViewController(_ vc: TransportFacilitiesViewController, didSelect facility: Facility?)
    @objc optional func transportFacilitiesViewControllerDidPressTransport(_ vc: TransportFacilitiesViewController)
}

class TransportFacilitiesViewController: UIViewController, TransportCartViewController, PRKit.FormFieldDelegate,
                                         UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var transportButton: PRKit.RoundButton!

    weak var delegate: TransportFacilitiesViewControllerDelegate?
    var cart: TransportCart?

    var results: Results<RegionFacility>?
    var notificationToken: NotificationToken?

    var incident: Incident?
    var reports: Results<Report>?
    var reportsNotificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        transportButton.titleLabel?.font = UIFont(name: "Barlow-SemiBold", size: 18) ?? .boldSystemFont(ofSize: 18)

        let layout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
        layout.estimatedItemSize = CGSize(width: 372, height: 276)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView.setCollectionViewLayout(layout, animated: false)

        var contentInset = collectionView.contentInset
        contentInset.bottom += transportButton.frame.height
        collectionView.contentInset = contentInset

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        collectionView.register(TransportFacilityCollectionViewCell.self, forCellWithReuseIdentifier: "Facility")

        updateCart()

        performQuery()
    }

    func performQuery() {
        let realm = AppRealm.open()

        // query for Facility
        notificationToken?.invalidate()
        if let regionId = AppSettings.regionId {
            results = realm.objects(RegionFacility.self).filter("regionId=%@", regionId).sorted(byKeyPath: "position", ascending: true)
            notificationToken = results?.observe { [weak self] (changes) in
                self?.didObserveRealmChanges(changes)
            }
        }

        // query for Report to populate Transported counts
        reportsNotificationToken?.invalidate()
        if let incident = incident {
            reports = realm.objects(Report.self).filter("incident=%@ AND canonicalId=%@", incident, NSNull())
            reportsNotificationToken = reports?.observe { [weak self] (changes) in
                self?.didObserveReportsChanges(changes)
            }
        }

        refresh()
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<RegionFacility>>) {
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

    func didObserveReportsChanges(_ changes: RealmCollectionChange<Results<Report>>) {
        for cell in collectionView.visibleCells {
            if let cell = cell as? TransportFacilityCollectionViewCell {
                cell.updateTransportedCounts(from: reports)
            }
        }
    }

    @objc func refresh() {
//        guard let sceneId = scene?.id else { return }
//        collectionView.reloadData()
//        collectionView.refreshControl?.beginRefreshing()
//        collectionView.setContentOffset(CGPoint(x: 0, y: -(collectionView.refreshControl?.frame.size.height ?? 0)), animated: true)
//        AppRealm.getResponders(sceneId: sceneId) { [weak self] (error) in
//            guard let self = self else { return }
//            if let error = error {
//                print(error)
//            }
//            DispatchQueue.main.async { [weak self] in
//                self?.collectionView.refreshControl?.endRefreshing()
//            }
//        }
        collectionView.refreshControl?.endRefreshing()
    }

    func updateCart() {
        guard let cart = cart, let stackView = stackView else { return }
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        if cart.reports.count > 0 || cart.responder != nil {
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
            if let responder = cart.responder {
                let field = TransportCartResponderField()
                field.delegate = self
                field.configure(from: responder)
                stackView.addArrangedSubview(field)
            }
        } else {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.heightAnchor.constraint(equalToConstant: 0).isActive = true
            stackView.addArrangedSubview(view)
        }

        transportButton.isEnabled = cart.reports.count > 0 && cart.responder != nil && cart.facility != nil
    }

    @IBAction
    func transportPressed(_ sender: RoundButton) {
        delegate?.transportFacilitiesViewControllerDidPressTransport?(self)
    }

    // MARK: - FormFieldDelegate

    func formFieldDidPress(_ field: FormField) {
        if let field = field as? TransportCartReportField {
            delegate?.transportFacilitiesViewController?(self, didRemoveReport: field.report)
        } else if let field = field as? TransportCartResponderField {
            delegate?.transportFacilitiesViewController?(self, didRemoveResponder: field.responder)
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Facility", for: indexPath)
        if let cell = cell as? TransportFacilityCollectionViewCell {
            let regionFacility = results?[indexPath.row]
            cell.configure(from: regionFacility, index: indexPath.row, isSelected: regionFacility?.facility == cart?.facility)
            cell.updateTransportedCounts(from: reports)
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        var indexPaths: [IndexPath] = []
        if let facility = cart?.facility {
            if let index = results?.firstIndex(where: { $0.facility == facility }) {
                indexPaths.append(IndexPath(row: index, section: 0))
            }
        }
        if let regionFacility = results?[indexPath.row] {
            delegate?.transportFacilitiesViewController?(self, didSelect: regionFacility.facility)
            indexPaths.append(indexPath)
        }
        for indexPath in indexPaths {
            if let cell = collectionView.cellForItem(at: indexPath) as? TransportFacilityCollectionViewCell {
                let regionFacility = results?[indexPath.row]
                cell.configure(from: regionFacility, index: indexPath.row, isSelected: regionFacility?.facility == cart?.facility)
            }
        }
        guard let cart = cart else { return }
        transportButton.isEnabled = cart.reports.count > 0 && cart.responder != nil && cart.facility != nil
    }
}
