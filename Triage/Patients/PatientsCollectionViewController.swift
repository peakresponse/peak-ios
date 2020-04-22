//
//  PatientsCollectionViewController.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

class PatientsCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var patientView: PatientView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        patientView.addShadow(withOffset: CGSize(width: 0, height: 4), radius: 4, color: UIColor.black, opacity: 0.1)
        contentView.layer.masksToBounds = false
        layer.masksToBounds = false
    }

    func configure(from patient: Patient) {
        patientView.configure(from: patient)
        nameLabel.text = patient.fullName
        updatedLabel.text = patient.updatedAtRelativeString
    }
}

class PatientsCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
}

class PatientsCollectionViewController: UIViewController, FilterViewDelegate, PriorityTabViewDelegate, SelectorViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    @IBOutlet weak var logoutItem: UIBarButtonItem!
    @IBOutlet weak var filterView: FilterView!
    weak var sortSelectorView: SelectorView?
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var collectionViewContainer: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var immediatePriorityView: PriorityTabView!
    @IBOutlet weak var delayedPriorityView: PriorityTabView!
    @IBOutlet weak var minimalPriorityView: PriorityTabView!
    @IBOutlet weak var expectantPriorityView: PriorityTabView!
    @IBOutlet weak var deadPriorityView: PriorityTabView!

    weak var refreshControl: UIRefreshControl!

    var notificationToken: NotificationToken?
    var results: Results<Patient>?
    var priority: Priority = .immediate
    var priorityTabViews: [Priority: PriorityTabView] = [:]
    var sort: Sort = .recent

    // MARK: -

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        /// set up priority to view mapping
        priorityTabViews[.immediate] = immediatePriorityView
        priorityTabViews[.delayed] = delayedPriorityView
        priorityTabViews[.minimal] = minimalPriorityView
        priorityTabViews[.expectant] = expectantPriorityView
        priorityTabViews[.dead] = deadPriorityView
        for (_, priorityTabView) in priorityTabViews {
            priorityTabView.delegate = self
        }

        /// set up collection view
        collectionViewContainer.addShadow(withOffset: CGSize(width: 1, height: 2), radius: 2, color: UIColor.black, opacity: 0.1)
        collectionViewContainer.layer.cornerRadius = 3
        collectionViewContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = UIColor.immediateRedLightened
        collectionView.layer.cornerRadius = 3
        collectionView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            layout.minimumInteritemSpacing = 10
            layout.minimumLineSpacing = 20
        }
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        self.refreshControl = refreshControl

        /// set up sort dropdown button
        filterView.delegate = self
        filterView.button.setTitle(sort.description, for: .normal)
        
        /// set up Realm query and observer
        performQuery()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// trigger additional refresh
        refresh()
    }

    private func performQuery() {
        notificationToken?.invalidate()
        var sorts = [
            SortDescriptor(keyPath: "priority", ascending: true)
        ]
        switch sort {
        case .recent:
            sorts.append(SortDescriptor(keyPath: "updatedAt", ascending: false))
        case .longest:
            sorts.append(SortDescriptor(keyPath: "updatedAt", ascending: true))
        case .az:
            sorts.append(SortDescriptor(keyPath: "lastName", ascending: true))
        case .za:
            sorts.append(SortDescriptor(keyPath: "lastName", ascending: false))
        }
        let realm = AppRealm.open()
        if let text = filterView.textField.text, !text.isEmpty {
            results = realm.objects(Patient.self).filter("firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@", text, text).sorted(by: sorts)
        } else {
            results = realm.objects(Patient.self).sorted(by: sorts)
        }
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
    }
    
    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Patient>>) {
        switch changes {
        case .initial(_):
            collectionView.reloadData()
            updateCounts()
        case .update(_, let deletions, let insertions, let modifications):
            /// if the collection view is empty just do a complete reload
            if Priority.allCases.reduce(0, {$0 + (priorityTabViews[$1]?.count ?? 0)}) == 0 {
                collectionView.reloadData()
                updateCounts()
                return
            }
            /// rewrite indices for the selected priority
            var startIndex = 0, endIndex = 0
            for priority in Priority.allCases {
                if priority == self.priority {
                    endIndex = startIndex + (priorityTabViews[priority]?.count ?? 0)
                    break
                }
                startIndex += (priorityTabViews[priority]?.count ?? 0)
            }
            var newDeletions: [Int] = []
            var newInsertions: [Int] = []
            var newModifications: [Int] = []
            for index in deletions {
                if index >= startIndex && index < endIndex {
                    newDeletions.append(index - startIndex)
                }
            }
            for index in insertions {
                if results?[index].priority.value == priority.rawValue {
                    newInsertions.append(index - startIndex)
                }
            }
            for index in modifications {
                if index >= startIndex && index < endIndex {
                    newModifications.append(index - startIndex)
                }
            }
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: newDeletions.map{ IndexPath(row: $0, section: 0) })
                collectionView.insertItems(at: newInsertions.map{ IndexPath(row: $0, section: 0) })
                collectionView.reloadItems(at: newModifications.map{ IndexPath(row: $0, section: 0) })
            }, completion: nil)
            updateCounts()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    @IBAction func logoutPressed(_ sender: Any) {
        logout()
    }

    @objc func refresh() {
        refreshControl.beginRefreshing()
        AppRealm.getPatients { [weak self] (error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.refreshControl.endRefreshing()
                    if let error = error as? ApiClientError, error == .unauthorized {
                        self?.presentLogin()
                    } else {
                        self?.presentAlert(error: error)
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.refreshControl.endRefreshing()
                }
            }
        }
    }

    func updateCounts() {
        for priority in Priority.allCases {
            priorityTabViews[priority]?.count = results?.reduce(into: 0) { $0 += $1.priority.value == priority.rawValue ? 1 : 0 } ?? 0
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let navVC = segue.destination as? UINavigationController,
            let vc = navVC.viewControllers[0] as? PatientTableViewController,
            let cell = sender as? PatientsCollectionViewCell,
            let indexPath = collectionView.indexPath(for: cell),
            let patient = results?.filter("priority=%@", priority.rawValue)[indexPath.row] {
            vc.patient = patient
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("DONE", comment: ""), style: .plain, target: self, action: #selector(dismissAnimated))
        }
    }

    // MARK: - FilterViewDelegate
    
    func filterView(_ filterView: FilterView, didChangeSearch text: String?) {
        performQuery()
    }
    
    func filterView(_ filterView: FilterView, didPressButton button: UIButton) {
        button.isSelected = !button.isSelected
        if button.isSelected {
            let sortSelectorView = SelectorView();
            sortSelectorView.delegate = self
            for sort in Sort.allCases {
                sortSelectorView.addButton(title: sort.description)
            }
            view.addSubview(sortSelectorView)
            NSLayoutConstraint.activate([
                sortSelectorView.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 0),
                sortSelectorView.rightAnchor.constraint(equalTo: button.rightAnchor, constant: 0),
                sortSelectorView.widthAnchor.constraint(equalToConstant: button.frame.width)
            ])
            self.sortSelectorView = sortSelectorView
        } else {
            sortSelectorView?.removeFromSuperview()
        }
    }

    // MARK: - LoginViewControllerDelegate
    
    override func loginViewControllerDidLogin(_ vc: LoginViewController) {
        dismiss(animated: true) { [weak self] in
            self?.refresh()
        }
    }

    // MARK: - PriorityTabViewDelegate

    func priorityTabViewDidChange(_ priorityTabView: PriorityTabView) {
        if priorityTabView.priority != priority {
            priorityTabViews[priority]?.isOpen = false
            priority = priorityTabView.priority
            collectionViewContainer.removeFromSuperview()
            collectionView.backgroundColor = PRIORITY_COLORS_LIGHTENED[priority.rawValue]
            stackView.insertArrangedSubview(collectionViewContainer, at: priority.rawValue + 1)
            collectionView.reloadData()
        }
    }

    // MARK: - SelectorViewDelegate
    
    func selectorView(_ view: SelectorView, didSelectButtonAtIndex index: Int) {
        filterView.button.isSelected = false
        if sort != Sort.allCases[index] {
            sort = Sort.allCases[index]
            filterView.button.setTitle(sort.description, for: .normal)
            performQuery()
        }
    }
    
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results?.reduce(into: 0) { $0 += $1.priority.value == priority.rawValue ? 1 : 0 } ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Patient", for: indexPath)
        if let cell = cell as? PatientsCollectionViewCell,
            let patient = results?.filter("priority=%@", priority.rawValue)[indexPath.row] {
            cell.configure(from: patient)
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var frame = collectionView.frame
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            frame = frame.inset(by: layout.sectionInset)
            frame.size.width = floor((frame.size.width - layout.minimumInteritemSpacing) / 2)
        }
        frame.size.height = 60
        return frame.size
    }
}
