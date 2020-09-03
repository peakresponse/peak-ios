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
    let priorityView = UIView()
    let priorityLabel = UILabel()
    let patientView = PatientView()
    let nameLabel = UILabel()
    let updatedLabel = UILabel()
    let genderLabel = UILabel()
    let ageLabel = UILabel()
    let complaintLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .white
        layer.cornerRadius = 3
        contentView.layer.cornerRadius = 3
        addShadow(withOffset: CGSize(width: 2, height: 2), radius: 4, color: .black, opacity: 0.1)
        
        priorityView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(priorityView)
        NSLayoutConstraint.activate([
            priorityView.topAnchor.constraint(equalTo: contentView.topAnchor),
            priorityView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            priorityView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            priorityView.heightAnchor.constraint(equalToConstant: 16)
        ])

        priorityLabel.translatesAutoresizingMaskIntoConstraints = false
        priorityLabel.font = .copyXSBold
        priorityLabel.textColor = .mainGrey
        contentView.addSubview(priorityLabel)
        NSLayoutConstraint.activate([
            priorityLabel.centerYAnchor.constraint(equalTo: priorityView.centerYAnchor),
            priorityLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -6)
        ])
        
        patientView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(patientView)
        NSLayoutConstraint.activate([
            patientView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            patientView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 6),
            patientView.widthAnchor.constraint(equalToConstant: 36),
            patientView.heightAnchor.constraint(equalToConstant: 36),
        ])
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .copyMBold
        nameLabel.textColor = .mainGrey
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: priorityView.bottomAnchor, constant: 2),
            nameLabel.leftAnchor.constraint(equalTo: patientView.rightAnchor, constant: 10)
        ])

        updatedLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedLabel.font = .copyXSRegular
        updatedLabel.textColor = .mainGrey
        contentView.addSubview(updatedLabel)
        NSLayoutConstraint.activate([
            updatedLabel.topAnchor.constraint(equalTo: priorityView.bottomAnchor, constant: 6),
            updatedLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -6)
        ])

        genderLabel.translatesAutoresizingMaskIntoConstraints = false
        genderLabel.font = .copySRegular
        genderLabel.textColor = .mainGrey
        contentView.addSubview(genderLabel)
        NSLayoutConstraint.activate([
            genderLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            genderLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor)
        ])
        
        ageLabel.translatesAutoresizingMaskIntoConstraints = false
        ageLabel.font = .copySRegular
        ageLabel.textColor = .mainGrey
        contentView.addSubview(ageLabel)
        NSLayoutConstraint.activate([
            ageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            ageLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor, constant: 60)
        ])
        
        complaintLabel.translatesAutoresizingMaskIntoConstraints = false
        complaintLabel.font = .copySRegular
        complaintLabel.textColor = .mainGrey
        contentView.addSubview(complaintLabel)
        NSLayoutConstraint.activate([
            complaintLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            complaintLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor, constant: 120)
        ])
    }

    func configure(from patient: Patient) {
        priorityView.backgroundColor = PRIORITY_COLORS_LIGHTENED[patient.priority.value ?? Priority.unknown.rawValue]
        priorityLabel.text = Priority(rawValue: patient.priority.value ?? Priority.unknown.rawValue)?.description ?? ""
        patientView.configure(from: patient)
        nameLabel.text = patient.fullName
        updatedLabel.text = patient.updatedAtRelativeString
        ageLabel.text = patient.ageString
    }
}

class PatientsCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
}

class PatientsCollectionViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UISearchBarDelegate, SortBarDelegate {
    @IBOutlet weak var searchBar: SearchBar!
    private var searchBarShouldBeginEditing = true
    @IBOutlet weak var sortBar: SortBar!
    @IBOutlet weak var collectionView: UICollectionView!

    weak var refreshControl: UIRefreshControl!

    var notificationToken: NotificationToken?
    var results: Results<Patient>?
    var priority: Priority?
    var sort: Sort = .recent

    // MARK: -

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        /// set up collection view
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets(top: 10, left: 22, bottom: 15, right: 22)
            layout.minimumInteritemSpacing = 10
            layout.minimumLineSpacing = 10
        }
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        self.refreshControl = refreshControl

        /// set up sort dropdown button
        sortBar.delegate = self
        sortBar.dropdownButton.setTitle(sort.description, for: .normal)
        
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
        var predicates: [NSPredicate] = []
        if let sceneId = AppSettings.sceneId {
            predicates.append(NSPredicate(format: "sceneId=%@", sceneId))
        }
        if let text = searchBar.text, !text.isEmpty {
            predicates.append(NSPredicate(format: "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@", text, text))
        }
        let predicate = predicates.count == 1 ? predicates[0] : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        results = realm.objects(Patient.self).filter(predicate).sorted(by: sorts)
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
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: deletions.map{ IndexPath(row: $0, section: 0) })
                collectionView.insertItems(at: insertions.map{ IndexPath(row: $0, section: 0) })
                collectionView.reloadItems(at: modifications.map{ IndexPath(row: $0, section: 0) })
            }, completion: nil)
            updateCounts()
        case .error(let error):
            presentAlert(error: error)
        }
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
//        for priority in Priority.allCases {
//            priorityTabViews[priority]?.count = results?.reduce(into: 0) { $0 += $1.priority.value == priority.rawValue ? 1 : 0 } ?? 0
//        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var results = self.results
        if let priority = priority {
            results = results?.filter("priority=%@", priority.rawValue)
        }
        if let vc = segue.destination as? PatientViewController,
            let cell = sender as? PatientsCollectionViewCell,
            let indexPath = collectionView.indexPath(for: cell),
            let patient = results?[indexPath.row] {
            vc.patient = patient
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized, style: .plain, target: self, action: #selector(dismissAnimated))
        }
    }

    // MARK: - SortBarDelegate

    func sortBar(_ sortBar: SortBar, willShow selectorView: SelectorView) {
        for sort in Sort.allCases {
            selectorView.addButton(title: sort.description)
        }
    }

    func sortBar(_ sortBar: SortBar, selectorView: SelectorView, didSelectButtonAtIndex index: Int) {
        if sort != Sort.allCases[index] {
            sort = Sort.allCases[index]
            sortBar.dropdownButton.setTitle(sort.description, for: .normal)
            performQuery()
        }
    }

    // MARK: - LoginViewControllerDelegate
    
    override func loginViewControllerDidLogin(_ vc: LoginViewController) {
        dismiss(animated: true) { [weak self] in
            self?.refresh()
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Patient", for: indexPath)
        if let cell = cell as? PatientsCollectionViewCell,
            let patient = results?[indexPath.row] {
            cell.configure(from: patient)
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var frame = collectionView.frame
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            frame = frame.inset(by: layout.sectionInset)
        }
        frame.size.height = 70
        return frame.size
    }
    
    // MARK: - UISearchBarDelegate
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchBar.isFirstResponder {
            searchBarShouldBeginEditing = false
        }
        performQuery()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        let result = searchBarShouldBeginEditing
        searchBarShouldBeginEditing = true
        return result
    }
}
