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

@objc protocol FacilitiesTableViewControllerDelegate {
    @objc optional func facilitiesTableViewControllerDidConfirmLeavingIndependently(_ vc: FacilitiesTableViewController)
}

class FacilitiesTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate,
                                     DropdownButtonDelegate, LocationHelperDelegate {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var leavingView: UIView!
    @IBOutlet weak var transportSwitch: UISegmentedControl!
    @IBOutlet weak var transportLabel: UILabel!
    @IBOutlet weak var searchBar: SearchBar!
    @IBOutlet weak var dropdownButton: DropdownButton!
    @IBOutlet weak var tableView: UITableView!
    weak var selectorView: SelectorView?

    weak var delegate: FacilitiesTableViewControllerDelegate?

    var locationHelper: LocationHelper!

    var observation: PatientObservation!

    var notificationToken: NotificationToken?
    var results: Results<Facility>?

    let types: [FacilityType] = [.all, .hospital, .morgueMortuary, .policeJail]
    var type: FacilityType = .hospital

    var debounceTimer: Timer?

    // MARK: -

    deinit {
        notificationToken?.invalidate()
        debounceTimer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        locationHelper = LocationHelper()
        locationHelper.delegate = self

        headerView.addShadow(withOffset: CGSize(width: 4, height: 4), radius: 20, color: .black, opacity: 0.2)

        transportSwitch.layer.borderColor = UIColor.greyPeakBlue.cgColor
        transportSwitch.layer.borderWidth = 2
        transportSwitch.setBackgroundImage(
            UIImage.resizableImage(withColor: .bgBackground, cornerRadius: 0), for: .normal, barMetrics: .default)
        transportSwitch.setBackgroundImage(
            UIImage.resizableImage(withColor: .greyPeakBlue, cornerRadius: 0), for: .selected, barMetrics: .default)
        transportSwitch.setTitle("FacilitiesTableViewController.facilityTitle".localized, forSegmentAt: 0)
        transportSwitch.setTitle("FacilitiesTableViewController.leavingTitle".localized, forSegmentAt: 1)
        transportSwitch.setTitleTextAttributes([
            .font: UIFont.copySBold,
            .foregroundColor: UIColor.greyPeakBlue
        ], for: .normal)
        transportSwitch.setTitleTextAttributes([
            .font: UIFont.copySBold,
            .foregroundColor: UIColor.white
        ], for: .selected)

        transportLabel.font = .copySBold
        transportLabel.textColor = .mainGrey
        transportLabel.text = "FacilitiesTableViewController.selectLabel".localized

        dropdownButton.setTitle(type.description, for: .normal)

        tableView.register(FacilityTableViewCell.self, forCellReuseIdentifier: "Facility")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        refresh()
    }

    @objc func refresh() {
        if let refreshControl = tableView.refreshControl, !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()

            var predicates: [NSPredicate] = []
            predicates.append(NSPredicate(format: "distance < %@", NSNumber(value: Double.greatestFiniteMagnitude)))
            if let text = searchBar.text, !text.isEmpty {
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
                locationHelper.requestLocation()
            }
        }
    }

    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Facility>>) {
        switch changes {
        case .initial:
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
        AppRealm.getFacilities(lat: lat, lng: lng, search: searchBar.text, type: type.rawValue) { (error) in
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
            }
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error: error)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let defaultNotificationCenter = NotificationCenter.default
        defaultNotificationCenter.addObserver(
            self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        defaultNotificationCenter.addObserver(
            self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // hack to trigger appropriate autolayout for header view- assign again, then trigger a second layout of just the tableView
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.layoutIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            view.layoutIfNeeded()
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
            UIView.animate(withDuration: duration) {
                self.headerViewTopConstraint.constant = 0
                self.tableView.contentInset.bottom = keyboardFrame.height
                self.tableView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25) {
            self.headerViewTopConstraint.constant = 140
            self.tableView.contentInset.bottom = 0
            self.tableView.verticalScrollIndicatorInsets.bottom = 0
            self.view.layoutIfNeeded()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AgenciesTableViewController,
            let indexPath = tableView.indexPathForSelectedRow,
            let facility = results?[indexPath.row] {
            vc.facility = facility
        }
    }

    @IBAction func transportSwitchChanged(_ sender: Any) {
        switch transportSwitch.selectedSegmentIndex {
        case 0:
            leavingView.isHidden = true
        case 1:
            leavingView.isHidden = false
        default:
            break
        }
    }

    @IBAction func confirmLeavingPressed(_ sender: Any) {
        delegate?.facilitiesTableViewControllerDidConfirmLeavingIndependently?(self)
        dismissAnimated()
    }

    @IBAction func unwindToFacilities(_ segue: UIStoryboardSegue) {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // MARK: - LocationHelper

    func locationHelper(_ helper: LocationHelper, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let lat = String(format: "%.6f", location.coordinate.latitude)
            let lng = String(format: "%.6f", location.coordinate.longitude)
            getFacilities(lat: lat, lng: lng)
        } else {
            tableView.refreshControl?.endRefreshing()
        }
    }

    func locationHelper(_ helper: LocationHelper, didFailWithError error: Error) {
        tableView.refreshControl?.endRefreshing()
        presentAlert(error: error)
    }

    // MARK: - DropdownButtonDelegate

    func dropdownWillAppear(_ button: DropdownButton) -> UIView? {
        return view
    }

    func dropdown(_ button: DropdownButton, willShow selectorView: SelectorView) {
        for type in types {
            selectorView.addButton(title: type.description)
        }
    }

    func dropdown(_ button: DropdownButton, selectorView: SelectorView, didSelectButtonAtIndex index: Int) {
        type = types[index]
        dropdownButton.setTitle(type.description, for: .normal)
        refresh()
    }

    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] (_) in
            self?.refresh()
        })
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Facility", for: indexPath)
        if let cell = cell as? FacilityTableViewCell, let facility = results?[indexPath.row] {
            cell.configure(from: facility)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "SelectAgency", sender: self)
    }
}
