//
//  FacilitiesTableViewController.swift
//  Triage
//
//  Created by Francis Li on 4/7/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
import RealmSwift
import UIKit

class FacilitiesTableViewController: UITableViewController, CLLocationManagerDelegate, FilterViewDelegate, SelectorViewDelegate {
    @IBOutlet weak var filterView: FilterView!
    weak var selectorView: SelectorView?

    let locationManager = CLLocationManager()

    var observation: Observation?
    var handler: ((FacilitiesTableViewController) -> ())?

    var notificationToken: NotificationToken?
    var results: Results<Facility>?

    let types: [FacilityType] = [.all, .hospital, .morgueMortuary, .policeJail]
    var type: FacilityType = .all
    
    // MARK: -
    
    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        filterView.button.setTitle(type.description, for: .normal)
        filterView.delegate = self
        
        tableView.register(UINib(nibName: "FacilityTableViewCell", bundle: nil), forCellReuseIdentifier: "Facility")
        tableView.tableFooterView = UIView()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refresh()
    }

    @objc func refresh() {
        if let refreshControl = refreshControl, !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()

            var predicates: [NSPredicate] = []
            predicates.append(NSPredicate(format: "distance < %@", NSNumber(value: Double.greatestFiniteMagnitude)))
            if let text = filterView.textField.text, !text.isEmpty {
                predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", text))
            }
            if type != .all {
                predicates.append(NSPredicate(format: "type = %@", type.rawValue))
            }

            let realm = AppRealm.open()
            results = realm.objects(Facility.self)
                .filter(NSCompoundPredicate(andPredicateWithSubpredicates: predicates))
                .sorted(by: [SortDescriptor(keyPath: "distance", ascending: true)])
            notificationToken = results?.observe { [weak self] (changes) in
                self?.didObserveRealmChanges(changes)
            }

            if let lat = observation?.lat, let lng = observation?.lng {
                getFacilities(lat: lat, lng: lng)
            } else {
                locationManager.requestWhenInUseAuthorization()
                locationManager.delegate = self
                /// reduce accuracy for a faster response
                locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                locationManager.requestLocation()
            }
        }
    }
    
    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Facility>>) {
        switch changes {
        case .initial(_):
            tableView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            self.tableView.endUpdates()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    func getFacilities(lat: String, lng: String) {
        AppRealm.getFacilities(lat: lat, lng: lng, search: filterView.textField.text, type: type.rawValue) { (error) in
            DispatchQueue.main.async { [weak self] in
                self?.refreshControl?.endRefreshing()
            }
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error: error)
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let lat = String(format: "%.6f", location.coordinate.latitude)
            let lng = String(format: "%.6", location.coordinate.longitude)
            getFacilities(lat: lat, lng: lng)
        } else {
            /// TODO: present error
            refreshControl?.endRefreshing()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        refreshControl?.endRefreshing()
        presentAlert(error: error)
    }

    // MARK: - FilterViewDelegate

    func filterView(_ filterView: FilterView, didChangeSearch text: String?) {
        refresh()
    }

    func filterView(_ filterView: FilterView, didPressButton button: UIButton) {
        button.isSelected = !button.isSelected
        if button.isSelected {
            let selectorView = SelectorView();
            selectorView.delegate = self
            for type in types {
                selectorView.addButton(title: type.description)
            }
            tableView.addSubview(selectorView)
            NSLayoutConstraint.activate([
                selectorView.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 0),
                selectorView.rightAnchor.constraint(equalTo: button.rightAnchor, constant: 0),
                selectorView.widthAnchor.constraint(equalToConstant: button.frame.width)
            ])
            self.selectorView = selectorView
        } else {
            selectorView?.removeFromSuperview()
        }
    }

    // MARK: - SelectorViewDelegate

    func selectorView(_ view: SelectorView, didSelectButtonAtIndex index: Int) {
        filterView.button.isSelected = false
        if type != types[index] {
            type = types[index]
            filterView.button.setTitle(type.description, for: .normal)
            refresh()
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Facility", for: indexPath)
        if let cell = cell as? FacilityTableViewCell, let facility = results?[indexPath.row] {
            cell.configure(from: facility)
        }
        return cell
    }

    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let facility = results?[indexPath.row] {
            return FacilityTableViewCell.height(for: facility)
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let facility = results?[indexPath.row] {
            observation?.transportFacility = facility
        }
        handler?(self)
    }
}
