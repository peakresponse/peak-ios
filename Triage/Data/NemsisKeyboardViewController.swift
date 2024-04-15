//
//  NemsisKeyboardViewController.swift
//  Triage
//
//  Created by Francis Li on 12/7/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import RealmSwift

class NemsisKeyboardViewController: SearchViewController, CodeListSectionsViewControllerDelegate {
    weak var segmentedControl: SegmentedControl!
    weak var containerView: UIView!

    var sources: [KeyboardSource]?
    var field: String?
    var fieldList: CodeList?
    var includeSystem = false
    var results: Results<CodeListItem>?
    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        source = sources?[0]
        isSearchFieldFocusedOnOpen = false
        super.viewDidLoad()

        // add a segmented control to switch between field list and full code list
        let segmentedControl = SegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
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

        // container view to hold list browsing views
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            containerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.containerView = containerView

        let realm = AppRealm.open()
        // look up the list for the field

        if let field = field {
            fieldList = realm.objects(CodeList.self).filter("%@ IN fields", field).first
            if let fieldList = fieldList {
                segmentedControl.addSegment(title: "NemsisKeyboardViewController.segment.suggested".localized)

                let storyboard = UIStoryboard(name: "CodeList", bundle: nil)
                if let vc = storyboard.instantiateInitialViewController() as? UINavigationController {
                    if let vc = vc.topViewController as? CodeListSectionsViewController {
                        vc.delegate = self
                        vc.values = values
                        vc.isMultiSelect = isMultiSelect
                        vc.list = fieldList
                        vc.includeSystem = includeSystem
                    }
                    addChild(vc)
                    vc.view.translatesAutoresizingMaskIntoConstraints = false
                    containerView.addSubview(vc.view)
                    NSLayoutConstraint.activate([
                        vc.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                        vc.view.leftAnchor.constraint(equalTo: containerView.leftAnchor),
                        vc.view.rightAnchor.constraint(equalTo: containerView.rightAnchor),
                        vc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
                    ])
                    vc.didMove(toParent: self)
                }

                // query for field list
                performQuery()
            }
        }

        if let sources = sources {
            for source in sources {
                segmentedControl.addSegment(title: source.name)
            }
            if fieldList == nil {
                containerView.isHidden = true
                source = sources[0]
                collectionView.reloadData()
            }
        }
    }

    @objc func segmentedControlValueChanged() {
        containerView.isHidden = segmentedControl.selectedIndex != 0
        if segmentedControl.selectedIndex > 0 {
            source = sources?[segmentedControl.selectedIndex - 1]
            collectionView.reloadData()
        }
    }

    func performQuery(_ query: String? = nil) {
        notificationToken?.invalidate()
        results = nil
        guard let query = query?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty else { return }
        guard let fieldList = fieldList else { return }
        let realm = AppRealm.open()
        // look up the list for the field
        results = realm.objects(CodeListItem.self).filter("list=%@", fieldList)
        results = results?.filter("name CONTAINS[cd] %@", query)
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
                self.collectionView.deleteItems(at: deletions.map { IndexPath(row: $0, section: 0) })
                self.collectionView.insertItems(at: insertions.map { IndexPath(row: $0, section: 0) })
                self.collectionView.reloadItems(at: modifications.map { IndexPath(row: $0, section: 0) })
            }, completion: nil)
        case .error(let error):
            presentAlert(error: error)
        }
    }

    // MARK: - CheckboxDelegate

    override func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        super.checkbox(checkbox, didChange: isChecked)
        if let navVC = children.first as? UINavigationController {
            for vc in navVC.children {
                if let vc = vc as? CodeListViewController {
                    vc.values = values
                    vc.reloadVisible()
                }
            }
        }
    }

    // MARK: - CodeListSectionsViewControllerDelegate

    func codeListSectionsViewController(_ vc: CodeListSectionsViewController, checkbox: Checkbox, didChange isChecked: Bool) {
        self.checkbox(checkbox, didChange: isChecked)
    }

    // MARK: - FormFieldDelegate

    open override func formComponentDidChange(_ component: PRKit.FormComponent) {
        if fieldList != nil, segmentedControl.selectedIndex == 0, let field = component as? PRKit.FormField {
            performQuery(field.text)
            containerView.isHidden = !(field.text?.isEmpty ?? true)
            return
        }
        super.formComponentDidChange(component)
    }

    // MARK: - UICollectionViewDataSource

    open override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if fieldList != nil, segmentedControl.selectedIndex == 0 {
            return 1
        }
        return super.numberOfSections(in: collectionView)
    }

    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if fieldList != nil, segmentedControl.selectedIndex == 0 {
            return results?.count ?? 0
        }
        return super.collectionView(collectionView, numberOfItemsInSection: section)
    }

    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if fieldList != nil, segmentedControl.selectedIndex == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Checkbox", for: indexPath)
            if let cell = cell as? SelectCheckboxCell, let item = results?[indexPath.row] {
                let value = NemsisValue(text: item.code)
                if includeSystem {
                    value.attributes = [:]
                    value.attributes?["CodeType"] = item.system
                }
                cell.checkbox.value = value
                if let sectionName = item.section?.name {
                    cell.checkbox.labelText = "\(sectionName): \(item.name ?? "")"
                } else {
                    cell.checkbox.labelText = item.name
                }
                cell.checkbox.delegate = self
                cell.checkbox.isRadioButton = !isMultiSelect
                if let value = cell.checkbox.value, values?.contains(value) ?? false {
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
