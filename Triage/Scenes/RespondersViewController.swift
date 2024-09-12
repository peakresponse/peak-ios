//
//  RespondersViewController.swift
//  Triage
//
//  Created by Francis Li on 2/23/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import AlignedCollectionViewFlowLayout
import Foundation
import PRKit
import RealmSwift
import UIKit

class RespondersViewController: SceneViewController, ResponderViewControllerDelegate,
                                ResponderCollectionViewCellDelegate, RespondersCountsHeaderViewDelegate,
                                UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addButton: PRKit.RoundButton!
    var formInputAccessoryView: UIView!

    var scene: Scene?
    var results: Results<Responder>?
    var notificationToken: NotificationToken?

    var filter: String?
    var filteredResults: Results<Responder>?
    var filteredNotificationToken: NotificationToken?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        tabBarItem.title = "TabBarItem.stage".localized
        tabBarItem.image = UIImage(named: "Stage", in: PRKitBundle.instance, compatibleWith: nil)
    }

    deinit {
        notificationToken?.invalidate()
        filteredNotificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = .background

        initSceneCommandHeader()

        formInputAccessoryView = FormInputAccessoryView(rootView: view)

        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        if let layout = layout {
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.sectionHeadersPinToVisibleBounds = true
        }

        var contentInset = collectionView.contentInset
        contentInset.bottom += addButton.frame.height
        collectionView.contentInset = contentInset

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        collectionView.register(ResponderCollectionViewCell.self, forCellWithReuseIdentifier: "Responder")
        collectionView.register(RespondersCountsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Counts")

        performQuery()

        isEditing = scene?.isResponder(userId: AppSettings.userId) ?? false
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            addButton.isHidden = false
        } else {
            addButton.isHidden = true
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

    override func performQuery() {
        notificationToken?.invalidate()
        filteredNotificationToken?.invalidate()

        let realm = AppRealm.open()
        guard let sceneId = AppSettings.sceneId else { return }
        scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)

        guard let scene = scene else { return }
        results = scene.responders.filter("(user=%@ OR vehicle<>%@) AND departedAt=%@", NSNull(), NSNull(), NSNull())
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

        filteredResults = results
        if let text = commandHeader.searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            filteredResults = filteredResults?.filter("(unitNumber CONTAINS[cd] %@) OR (vehicle.number CONTAINS[cd] %@) OR (user.firstName CONTAINS[cd] %@) OR (user.lastName CONTAINS[cd] %@)",
                                              text, text, text, text)
        }
        if let filter = filter {
            filteredResults = filteredResults?.filter(filter)
        }
        filteredNotificationToken = filteredResults?.observe { [weak self] (changes) in
            self?.didObserveFilteredRealmChanges(changes)
        }

        collectionView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
        refresh()
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Responder>>) {
        switch changes {
        case .initial:
            fallthrough
        case .update:
            if let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: 0)) as? RespondersCountsHeaderView {
                headerView.configure(from: results)
            }
        case .error(let error):
            presentAlert(error: error)
        }
    }

    func didObserveFilteredRealmChanges(_ changes: RealmCollectionChange<Results<Responder>>) {
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
        collectionView.reloadData()
        collectionView.refreshControl?.beginRefreshing()
        collectionView.setContentOffset(CGPoint(x: 0, y: -(collectionView.refreshControl?.frame.size.height ?? 0)), animated: true)
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

    // MARK: - ResponderCollectionViewCellDelegate

    func responderCollectionViewCellDidMarkArrived(_ cell: ResponderCollectionViewCell, responderId: String?) {
        guard let responderId = responderId else { return }
        AppRealm.markResponderArrived(responderId: responderId) { _ in
        }
    }

    // MARK: - ResponderViewControllerDelegate

    func responderViewControllerDidSave(_ vc: ResponderViewController) {
        dismissAnimated()
    }

    // MARK: - RespondersCountsHeaderViewDelegate

    func respondersCountsHeaderView(_ view: RespondersCountsHeaderView, didPressArrived button: Button) {
        filter = "arrivedAt<>NULL"
        performQuery()
    }

    func respondersCountsHeaderView(_ view: RespondersCountsHeaderView, didPressEnroute button: Button) {
        filter = "arrivedAt=NULL"
        performQuery()
    }

    func respondersCountsHeaderView(_ view: RespondersCountsHeaderView, didPressTotal button: Button) {
        filter = nil
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Responder", for: indexPath)
        if let cell = cell as? ResponderCollectionViewCell {
            cell.delegate = self
            if indexPath.row < (filteredResults?.count ?? 0), let responder = filteredResults?[indexPath.row] {
                cell.configure(from: responder, index: indexPath.row)
                cell.button.isEnabled = isEditing
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Counts", for: indexPath)
        if let headerView = headerView as? RespondersCountsHeaderView {
            headerView.delegate = self
            headerView.configure(from: results)
        }
        return headerView
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let responder = filteredResults?[indexPath.row] else { return }
        if isEditing && responder.user == nil && responder.vehicle == nil {
            let vc = UIStoryboard(name: "Scenes", bundle: nil).instantiateViewController(withIdentifier: "Responder")
            if let vc = vc as? ResponderViewController, let responder = filteredResults?[indexPath.row] {
                vc.delegate = self
                vc.responder = responder
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized, style: .plain, target: self, action: #selector(dismissAnimated))
                vc.isEditing = true
            }
            presentAnimated(vc)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if traitCollection.horizontalSizeClass == .regular {
            return CGSize(width: 372, height: 125)
        }
        return CGSize(width: view.frame.width, height: 125)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 0, height: 60)
    }
}
