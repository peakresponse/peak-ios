//
//  CodeListItemsViewController.swift
//  Triage
//
//  Created by Francis Li on 12/7/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import PRKit
import RealmSwift

protocol CodeListItemsViewControllerDelegate: AnyObject {
    func codeListItemsViewController(_ vc: CodeListItemsViewController, checkbox: Checkbox, didChange isChecked: Bool)
}

class CodeListItemsViewController: UIViewController, CheckboxDelegate, CommandHeaderDelegate, KeyboardAwareScrollViewController,
                                   UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var collectionView: UICollectionView!
    var scrollView: UIScrollView! { return collectionView }
    @IBOutlet var scrollViewBottomConstraint: NSLayoutConstraint!

    weak var delegate: CodeListItemsViewControllerDelegate?
    var isMultiSelect = false
    var values: [String]?
    var list: CodeList?
    var section: CodeListSection?
    var results: Results<CodeListItem>?
    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(SelectCheckboxCell.self, forCellWithReuseIdentifier: "Checkbox")

        let realm = AppRealm.open()
        results = realm.objects(CodeListItem.self)
        if let section = section {
            results = results?.filter("section=%@", section)

            let backButton = UIBarButtonItem(title: "Button.back".localized, style: .plain, target: self, action: #selector(backPressed))
            backButton.image = UIImage(named: "ChevronLeft40px", in: PRKitBundle.instance, compatibleWith: nil)
            commandHeader.leftBarButtonItem = backButton

            let titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.font = .h3SemiBold
            titleLabel.textColor = .base800
            titleLabel.numberOfLines = 1
            titleLabel.text = section.name
            if let view = commandHeader.leftBarButtonView, let button = view.subviews.first,
                let rightConstraint = view.constraints.filter({ ($0.firstItem as? UIButton) == button && $0.firstAttribute == .right }).first {
                rightConstraint.isActive = false
                button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                commandHeader.leftBarButtonView?.addSubview(titleLabel)
                NSLayoutConstraint.activate([
                    titleLabel.leftAnchor.constraint(equalTo: button.rightAnchor, constant: 20),
                    titleLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
                    titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor)
                ])
            }
        } else {
            commandHeader.heightAnchor.constraint(equalToConstant: 0).isActive = true
            if let list = list {
                results = results?.filter("list=%@", list)
            }
        }
        results = results?.sorted(byKeyPath: "name", ascending: true)
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<CodeListItem>>) {
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

    @objc func backPressed() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - CheckboxDelegate

    func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        delegate?.codeListItemsViewController(self, checkbox: checkbox, didChange: isChecked)
        collectionView.reloadData()
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Checkbox", for: indexPath)
        if let cell = cell as? SelectCheckboxCell, let item = results?[indexPath.row] {
            cell.checkbox.value = item.code
            cell.checkbox.labelText = item.name
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
}
