//
//  ObservationTableViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

@objc protocol ObservationTableViewControllerDelegate {
    @objc optional func observationTableViewControllerDidDismiss(_ vc: ObservationTableViewController)
    @objc optional func observationTableViewController(_ vc: ObservationTableViewController, didSave observation: Observation)
}

class ObservationTableViewController: PatientTableViewController {
    weak var delegate: ObservationTableViewControllerDelegate?
    
    var rightBarButtonItems: [UIBarButtonItem]!
    var observation: Observation!

    override func viewDidLoad() {
        super.viewDidLoad()

        observation = patient.asObservation()
        
        tableView.register(UINib(nibName: "AttributeTableViewCell", bundle: nil), forCellReuseIdentifier: "Attribute")
        tableView.register(UINib(nibName: "PortraitTableViewCell", bundle: nil), forCellReuseIdentifier: "Portrait")
        tableView.register(UINib(nibName: "PriorityTableViewCell", bundle: nil), forCellReuseIdentifier: "Priority")
        tableView.tableFooterView = UIView()

        if title == "" {
            title = NSLocalizedString("New Patient", comment: "")
        }
        
        rightBarButtonItems = navigationItem.rightBarButtonItems
    }

    @IBAction func cancelPressed(_ sender: Any) {
        delegate?.observationTableViewControllerDidDismiss?(self)
    }
    
    @IBAction func savePressed(_ sender: Any) {
        if observation.priority.value == nil {
            presentAlert(title: NSLocalizedString("Error", comment: ""), message: "Please select a SALT priority")
            return
        }
        
        let activityView = UIActivityIndicatorView(style: .gray)
        activityView.startAnimating()
        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: activityView)]
        let task = ApiClient.shared.createObservation(observation.asJSON()) { [weak self] (record, error) in
            var observation: Observation?
            if let record = record {
                observation = Observation.instantiate(from: record) as? Observation
                if let observation = observation {
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(observation, update: .modified)
                    }
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.navigationItem.rightBarButtonItems = self?.rightBarButtonItems
                if let error = error {
                    self?.presentAlert(error: error)
                } else if let observation = observation, let self = self {
                    self.delegate?.observationTableViewController?(self, didSave: observation)
                }
            }
        }
        task.resume()
    }
    
    @IBAction func recordPressed(_ sender: Any) {
    }

    // MARK: - AttributeTableViewCellDelegate

    func attributeTableViewCell(_ cell: AttributeTableViewCell, didChange text: String) {
        observation.setValue(text, forKey: cell.attribute)
    }
    
    // MARK: - PriorityViewDelegate
    
    override func priorityView(_ view: PriorityView, didSelect priority: Int) {
        observation.priority.value = priority
        tableView.reloadSections(IndexSet(arrayLiteral: 0, 1), with: .none)
        view.removeFromSuperview()
    }

    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let cell = cell as? PatientTableViewCell {
            cell.configure(from: observation)
            cell.editable = true
        }
        return cell
    }
}
