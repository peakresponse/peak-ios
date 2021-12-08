//
//  ICD10CMViewController.swift
//  Triage
//
//  Created by Francis Li on 12/7/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import RealmSwift

class ICD10CMViewController: SearchViewController {
    weak var segmentedControl: SegmentedControl!
    var field: String?

    var results: Results<CodeListItem>?
    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if field != nil {
            // add a segmented control to switch between field list and full code list
            let segmentedControl = SegmentedControl()
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            segmentedControl.addSegment(title: "ICD10CMViewController.segment.subset".localized)
            segmentedControl.addSegment(title: "ICD10CMViewController.segment.full".localized)
            segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
            view.addSubview(segmentedControl)
            NSLayoutConstraint.activate([
                segmentedControl.topAnchor.constraint(equalTo: commandHeader.bottomAnchor, constant: 10),
                segmentedControl.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
                segmentedControl.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20)
            ])
            self.segmentedControl = segmentedControl

            // reposition search field
            for constraint in view.constraints {
                if constraint.firstItem as? PRKit.TextField != nil, constraint.secondItem as? CommandHeader != nil {
                    constraint.isActive = false
                    break
                }
            }
            searchField.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10).isActive = true

            // query for field list
            performQuery()
        }
    }

    @objc func segmentedControlValueChanged() {
        collectionView.reloadData()
    }

    func performQuery(_ query: String? = nil) {
        notificationToken?.invalidate()
        guard let field = field else { return }
        let realm = AppRealm.open()
        // look up the list for the field
        let list = realm.objects(CodeList.self).filter("%@ IN fields", field).first
        guard let list = list else { return }
        results = realm.objects(CodeListItem.self).filter("list=%@", list)
        if let query = query {
            results = results?.filter("name CONTAINS[cd] %@", query)
        }
        results = results?.sorted(by: [
            SortDescriptor(keyPath: "section.position", ascending: true),
            SortDescriptor(keyPath: "section.name", ascending: true),
            SortDescriptor(keyPath: "name", ascending: true)
        ])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<CodeListItem>>) {
        guard segmentedControl.selectedIndex == 0 else { return }
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

    // MARK: - FormFieldDelegate

    open override func formFieldDidChange(_ field: PRKit.FormField) {
        if self.field != nil, segmentedControl.selectedIndex == 0 {
            performQuery(field.text)
            return
        }
        super.formFieldDidChange(field)
    }

    // MARK: - UICollectionViewDataSource

    open override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if field != nil, segmentedControl.selectedIndex == 0 {
            return 1
        }
        return super.numberOfSections(in: collectionView)
    }

    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if field != nil, segmentedControl.selectedIndex == 0 {
            return results?.count ?? 0
        }
        return super.collectionView(collectionView, numberOfItemsInSection: section)
    }

    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if field != nil, segmentedControl.selectedIndex == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Checkbox", for: indexPath)
            if let cell = cell as? SelectCheckboxCell {
                let item = results?[indexPath.row]
                cell.checkbox.value = item?.code
                cell.checkbox.labelText = item?.name
                cell.checkbox.delegate = self
                cell.checkbox.isRadioButton = !isMultiSelect
                if let value = cell.checkbox.value as? String, values?.contains(value) ?? false {
                    cell.checkbox.isChecked = true
                } else {
                    cell.checkbox.isChecked = false
                }
            }
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
}
