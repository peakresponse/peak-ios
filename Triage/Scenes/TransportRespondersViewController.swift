//
//  TransportRespondersViewController.swift
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

@objc protocol TransportRespondersViewControllerDelegate {
    @objc optional func transportRespondersViewController(_ vc: TransportRespondersViewController, didSelect responder: Responder?)
    @objc optional func transportRespondersViewController(_ vc: TransportRespondersViewController, didRemove report: Report?)
}

class TransportRespondersViewController: UIViewController, ResponderCollectionViewCellDelegate,
                                         TransportCartViewController, ResponderViewControllerDelegate, PRKit.FormFieldDelegate,
                                         UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addButton: PRKit.RoundButton!

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

        let layout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView.setCollectionViewLayout(layout, animated: false)

        var contentInset = collectionView.contentInset
        contentInset.bottom += addButton.frame.height
        collectionView.contentInset = contentInset

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        collectionView.register(ResponderCollectionViewCell.self, forCellWithReuseIdentifier: "Responder")

        let realm = AppRealm.open()
        guard let sceneId = AppSettings.sceneId else { return }
        scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
        isEditing = scene?.isResponder(userId: AppSettings.userId) ?? false
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        addButton.isHidden = !editing
        for cell in collectionView.visibleCells {
            if let cell = cell as? ResponderCollectionViewCell {
                cell.checkbox.isEnabled = editing
                cell.button.isEnabled = editing
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if traitCollection.horizontalSizeClass == .regular {
            if let layout = collectionView.collectionViewLayout as? AlignedCollectionViewFlowLayout {
                var sectionInset = layout.sectionInset
                let inset = max(0, (collectionView.frame.width - 744) / 2)
                sectionInset.left = inset
                sectionInset.right = inset
                layout.sectionInset = sectionInset
            }
        }
    }

    func performQuery(_ searchText: String? = nil) {
        notificationToken?.invalidate()

        guard let scene = scene else { return }
        results = scene.responders.filter("departedAt=%@", NSNull())
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

    @objc func refresh() {
        guard let sceneId = scene?.id else { return }
        // force reload of all cells to update timestamps
        collectionView.reloadData()
        AppRealm.getResponders(sceneId: sceneId) { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                print(error)
            }
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.refreshControl?.endRefreshing()
            }
        }
    }

    @IBAction
    func addPressed(_ sender: RoundButton) {
        let vc = UIStoryboard(name: "Scenes", bundle: nil).instantiateViewController(withIdentifier: "Responder")
        if let vc = vc as? ResponderViewController {
            vc.delegate = self
            let responder = Responder()
            responder.scene = scene
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized, style: .plain, target: self, action: #selector(dismissAnimated))
            vc.responder = responder
            vc.isEditing = true
        }
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
            if let cell = collectionView.cellForItem(at: indexPath) as? ResponderCollectionViewCell {
                let responder = results?[indexPath.row]
                cell.configure(from: responder, index: indexPath.row, isSelected: responder == cart?.responder)
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

    // MARK: - ResponderCollectionViewCellDelegate

    func responderCollectionViewCell(_ cell: ResponderCollectionViewCell, didToggle isSelected: Bool) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        didToggleItem(at: indexPath)
    }

    func responderCollectionViewCellDidMarkArrived(_ cell: ResponderCollectionViewCell, responderId: String?) {
        guard let responderId = responderId else { return }
        AppRealm.markResponderArrived(responderId: responderId) { _ in
        }
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        didToggleItem(at: indexPath)
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Responder", for: indexPath)
        if let cell = cell as? ResponderCollectionViewCell, indexPath.row < (results?.count ?? 0) {
            let responder = results?[indexPath.row]
            cell.delegate = self
            cell.isSelectable = true
            cell.configure(from: responder, index: indexPath.row, isSelected: responder == cart?.responder)
            cell.checkbox.isEnabled = isEditing
            cell.button.isEnabled = isEditing
        }
        return cell
    }
}
