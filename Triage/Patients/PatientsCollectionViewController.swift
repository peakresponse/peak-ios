//
//  PatientsCollectionViewController.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class PatientsCollectionViewController: UICollectionViewController, LoginViewControllerDelegate {
    @IBOutlet weak var logoutItem: UIBarButtonItem!
    weak var refreshControl: UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
        self.refreshControl = refreshControl

        // Register cell classes
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        refresh()
    }
    
    @IBAction func logoutPressed(_ sender: Any) {
        ApiClient.shared.logout { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.presentLogin()
            }
        }
    }
    
    @objc func refresh() {
        if !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
            let task = ApiClient.shared.listPatients { [weak self] (results, error) in
                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        self?.refreshControl.endRefreshing()
                        if let error = error as? ApiClientError, error == .unauthorized {
                            self?.presentLogin()
                        } else {
                            self?.presentAlert(error: error)
                        }
                    }
                } else if let results = results {
                    DispatchQueue.main.async { [weak self] in
                        self?.refreshControl.endRefreshing()
                        print(results)
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
    
    // MARK: - LoginViewControllerDelegate
    
    func loginViewControllerDidLogin(_ vc: LoginViewController) {
        dismiss(animated: true) { [weak self] in
            self?.refresh()
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
    
        return cell
    }

    // MARK: UICollectionViewDelegate

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
