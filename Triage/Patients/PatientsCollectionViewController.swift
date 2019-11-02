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
    
    func configure(from patient: Patient) {
        patientView.configure(from: patient)
    }
}

class PatientsCollectionViewController: UICollectionViewController, LoginViewControllerDelegate {
    @IBOutlet weak var logoutItem: UIBarButtonItem!
    weak var refreshControl: UIRefreshControl!

    var notificationToken: NotificationToken?
    var results: Results<Patient>?

    // MARK: -
    
    deinit {
        notificationToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //// set up pull-to-refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
        self.refreshControl = refreshControl

        //// set up Realm query and observer
        let realm = AppRealm.open()
        results = realm.objects(Patient.self).sorted(by: [
            SortDescriptor(keyPath: "priority", ascending: true),
            SortDescriptor(keyPath: "updatedAt", ascending: true)
        ])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
        
        //// trigger initial refresh
        refresh()
    }
    
    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Patient>>) {
        switch changes {
        case .initial(_):
            collectionView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: deletions.map{ IndexPath(row: $0, section: 0)})
                collectionView.insertItems(at: insertions.map{ IndexPath(row: $0, section: 0)})
                collectionView.reloadItems(at: modifications.map{ IndexPath(row: $0, section: 0)})
            }, completion: nil)
        case .error(let error):
            presentAlert(error: error)
        }
    }
    
    @IBAction func logoutPressed(_ sender: Any) {
        ApiClient.shared.logout { [weak self] in
            AppRealm.deleteAll()
            DispatchQueue.main.async { [weak self] in
                self?.presentLogin()
            }
        }
    }
    
    @objc func refresh() {
        if !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
            let task = ApiClient.shared.listPatients { [weak self] (records, error) in
                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        self?.refreshControl.endRefreshing()
                        if let error = error as? ApiClientError, error == .unauthorized {
                            self?.presentLogin()
                        } else {
                            self?.presentAlert(error: error)
                        }
                    }
                } else if let records = records {
                    let patients = records.map({ Patient.instantiate(from: $0) })
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(patients, update: .modified)
                    }
                    DispatchQueue.main.async { [weak self] in
                        self?.refreshControl.endRefreshing()
                    }
                }
            }
            task.resume()
        }
    }

    private func presentLogin() {
        if let vc = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() as? LoginViewController {
            vc.loginDelegate = self
            present(vc, animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let vc = segue.destination as? PatientTableViewController,
            let cell = sender as? PatientsCollectionViewCell,
            let indexPath = collectionView.indexPath(for: cell),
            let patient = results?[indexPath.row] {
            vc.patient = patient
        }
    }

    // MARK: - LoginViewControllerDelegate
    
    func loginViewControllerDidLogin(_ vc: LoginViewController) {
        dismiss(animated: true) { [weak self] in
            self?.refresh()
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Patient", for: indexPath)
        if let cell = cell as? PatientsCollectionViewCell,
            let patient = results?[indexPath.row] {
            cell.configure(from: patient)
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
