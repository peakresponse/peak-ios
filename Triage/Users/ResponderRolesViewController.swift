//
//  ResponderRolesViewController.swift
//  Triage
//
//  Created by Francis Li on 5/29/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import AlignedCollectionViewFlowLayout
import PRKit
import RealmSwift
import UIKit

class ResponderRolesViewController: UIViewController, CommandHeaderDelegate, PRKit.FormFieldDelegate, PRKit.KeyboardSource,
                                    UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var collectionView: UICollectionView!
    var formInputAccessoryView: UIView!

    var scene: Scene?
    var results: Results<Responder>?
    var roles: [ResponderRole] = []
    var notificationToken: NotificationToken?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        tabBarItem.title = "TabBarItem.rolesResources".localized
        tabBarItem.image = UIImage(named: "Transport", in: PRKitBundle.instance, compatibleWith: nil)
    }

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        commandHeader.searchField.delegate = self

        formInputAccessoryView = FormInputAccessoryView(rootView: view)

        let layout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView.setCollectionViewLayout(layout, animated: false)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        collectionView.register(ResponderCollectionViewCell.self, forCellWithReuseIdentifier: "Responder")

        performQuery()
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

    func performQuery() {
        notificationToken?.invalidate()

        let realm = AppRealm.open()
        guard let sceneId = AppSettings.sceneId else { return }
        scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)

        guard let scene = scene else { return }
        results = scene.responders.filter("departedAt=%@", NSNull())
        if let text = commandHeader.searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            results = results?.filter("(vehicle.number CONTAINS[cd] %@) OR (user.firstName CONTAINS[cd] %@) OR (user.lastName CONTAINS[cd] %@)",
                                      text, text, text)
        }
        results = results?.sorted(by: [
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
                self.collectionView.insertItems(at: insertions.map { IndexPath(row: $0, section: 0) })
                self.collectionView.deleteItems(at: deletions.map { IndexPath(row: $0, section: 0) })
                self.collectionView.reloadItems(at: modifications.map { IndexPath(row: $0, section: 0) })
            }, completion: nil)
        case .error(let error):
            presentAlert(error: error)
        }
    }

    @objc func refresh() {

    }

    // MARK: - FormFieldDelegate
    func formFieldShouldBeginEditing(_ field: PRKit.FormField) -> Bool {
        if let responder = field.source as? Responder {
            let isSelf = AppSettings.userId == responder.user?.id
            let isMGS = scene?.mgsResponderId == responder.id
            if isMGS && isSelf {
                // cannot edit own roles until MGS transferred to another responder
                return false
            }
            roles = [.triage, .treatment, .staging, .transport]
            if isMGS || isSelf {
                roles.insert(.mgs, at: 0)
            }
        }
        return true
    }

    func formFieldDidChange(_ field: PRKit.FormField) {
        if field == commandHeader.searchField {
            performQuery()
        } else {
            if let roleValue = field.attributeValue as? String, let role = ResponderRole(rawValue: roleValue),
               let responder = field.source as? Responder {
                AppRealm.assignResponder(responderId: responder.id, role: role)
            }
        }
    }

    func formFieldShouldReturn(_ field: PRKit.FormField) -> Bool {
        if field == commandHeader.searchField {
            field.resignFirstResponder()
        }
        return false
    }

    // MARK: - KeyboardSource

    var name: String {
        return "ResponderRole"
    }

    func count() -> Int {
        return roles.count
    }

    func firstIndex(of value: NSObject) -> Int? {
        return nil
    }

    func search(_ query: String?, callback: ((Bool) -> Void)? = nil) {
        callback?(false)
    }

    func title(for value: NSObject?) -> String? {
        guard let value = value as? String else { return nil }
        return roles.first(where: {$0.rawValue == value})?.description
    }

    func title(at index: Int) -> String? {
        return roles[index].description
    }

    func value(at index: Int) -> NSObject? {
        return roles[index].rawValue as NSObject
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
        if let cell = cell as? ResponderCollectionViewCell {
            let responder = results?[indexPath.row]
            let isMGS = scene?.mgsResponderId == responder?.id
            cell.configure(from: responder, index: indexPath.row, isMGS: isMGS)
            cell.roleSelector.delegate = self
            cell.roleSelector.inputAccessoryView = formInputAccessoryView
        }
        return cell
    }
}
