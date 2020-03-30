//
//  PatientTableViewController.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

let INFO = ["firstName", "lastName", "age"]
let INFO_TYPES: [AttributeTableViewCellType] = [.string, .string, .number]

let VITALS = ["respiratoryRate", "pulse", "capillaryRefill", "bloodPressure"]
let VITALS_TYPES: [AttributeTableViewCellType] = [.number, .number, .number, .string]

class PatientTableViewController: UITableViewController, AttributeTableViewCellDelegate, LatLngTableViewCellDelegate, ObservationTableViewControllerDelegate, PriorityViewDelegate, ObservationTableViewCellDelegate {
    enum Section: Int, CaseIterable {
        case portrait = 0
        case location
        case info
        case vitals
        case observations
    }

    var updateButton: Button!
    var patient: Patient!
    var notificationToken: NotificationToken?
    
    deinit {
        notificationToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "AttributeTableViewCell", bundle: nil), forCellReuseIdentifier: "Attribute")
        tableView.register(UINib(nibName: "LatLngTableViewCell", bundle: nil), forCellReuseIdentifier: "LatLng")
        tableView.register(UINib(nibName: "ObservationTableViewCell", bundle: nil), forCellReuseIdentifier: "Observation")
        tableView.register(UINib(nibName: "PortraitTableViewCell", bundle: nil), forCellReuseIdentifier: "Portrait")
        tableView.register(UINib(nibName: "TableViewHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Footer")
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 85, right: 0)
        tableView.tableFooterView = UIView()
        
        if patient.id != nil {
            notificationToken = patient.observe { [weak self] (change) in
                self?.didObserveChange(change)
            }
        }

        updateButton = Button(frame: CGRect(x: 0, y: 0, width: 150, height: 44))
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.backgroundColor = .natBlue
        updateButton.tintColor = .white
        updateButton.adjustsImageWhenHighlighted = false
        updateButton.titleLabel?.font = UIFont(name: "NunitoSans-SemiBold", size: 18)
        updateButton.setTitle(NSLocalizedString(" UPDATE", comment: ""), for: .normal)
        updateButton.setImage(UIImage(named: "Edit"), for: .normal)
        updateButton.addTarget(self, action: #selector(updatePressed(_:)), for: .touchUpInside)
    }

    @objc func updatePressed(_ sender: Any) {
        if let navVC = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(identifier: "Observation") as? UINavigationController,
            let vc = navVC.viewControllers[0] as? ObservationTableViewController {
            vc.delegate = self
            vc.patient = patient.asObservation()
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("CANCEL", comment: ""), style: .done, target: self, action: #selector(dismissAnimated))
            presentAnimated(navVC)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateButton.removeFromSuperview()
        if let superview = tableView.superview {
            superview.addSubview(updateButton)
            NSLayoutConstraint.activate([
                updateButton.widthAnchor.constraint(equalToConstant: 150),
                updateButton.heightAnchor.constraint(equalToConstant: 44),
                updateButton.centerXAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerXAnchor),
                updateButton.bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            ])
        }
    }
    
    func didObserveChange(_ change: ObjectChange) {
        switch change {
        case .change(_):
            tableView.reloadData()
        case .error(let error):
            presentAlert(error: error)
        case .deleted:
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - AttributeTableViewCellDelegate

    func attributeTableViewCellDidReturn(_ cell: AttributeTableViewCell) {
        var next: UITableViewCell?
        if let indexPath = tableView.indexPath(for: cell) {
            if indexPath.row < tableView.numberOfRows(inSection: indexPath.section) - 1 {
                if let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row + 1, section: indexPath.section)) {
                    next = cell
                }
            }
        }
        if let cell = next, cell.becomeFirstResponder() {
            return
        }
        _ = resignFirstResponder()
    }

    // MARK: - ObservationTableViewControllerDelegate
    
    func observationTableViewController(_ vc: ObservationTableViewController, didSave observation: Observation) {
        if let id = patient.id {
            AppRealm.getPatient(idOrPin: id) { (error) in
                DispatchQueue.main.async { [weak self] in
                    if let error = error {
                        self?.presentAlert(error: error)
                    }
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }

    // MARK: - PriorityViewDelegate

    func priorityView(_ view: PriorityView, didSelect priority: Int) {
        let patientId = patient.id
        let observation = Observation()
        observation.pin = patient.pin
        observation.priority.value = priority
        AppRealm.createObservation(observation) { (observation, error) in
            DispatchQueue.main.async { [weak self] in
                if let error = error {
                    self?.presentAlert(error: error)
                } else {
                    if let patientId = patientId {
                        AppRealm.getPatient(idOrPin: patientId) { [weak self] (error) in
                            DispatchQueue.main.async { [weak self] in
                                if let error = error {
                                    self?.presentAlert(error: error)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Section.portrait.rawValue:
            return 180
        case Section.observations.rawValue:
            if let text = patient.text {
                return ObservationTableViewCell.heightForText(text, width: tableView.frame.width)
            }
        default:
            break
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Section.location.rawValue:
            if indexPath.row == 1 {
                if let lat = patient.lat, let lng = patient.lng, lat != "", lng != "" {
                    if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Map") as? PatientMapViewController {
                        vc.patient = patient
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.tableView(tableView, titleForHeaderInSection: section) != nil {
            return 32
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as? TableViewHeaderView {
            headerView.customLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
            return headerView
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case Section.portrait.rawValue:
            return 20
        default:
            return 8
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Footer")
        footerView?.backgroundView = UIView()
        return footerView
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.location.rawValue:
            return NSLocalizedString("Location", comment: "")
        case Section.info.rawValue:
            return NSLocalizedString("Info", comment: "")
        case Section.vitals.rawValue:
            return NSLocalizedString("Vitals", comment: "")
        case Section.observations.rawValue:
            return NSLocalizedString("Observation", comment: "")
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.portrait.rawValue:
            return 1
        case Section.location.rawValue:
            return 2
        case Section.info.rawValue:
            return INFO.count
        case Section.vitals.rawValue:
            return VITALS.count
        case Section.observations.rawValue:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case Section.portrait.rawValue:
            cell = tableView.dequeueReusableCell(withIdentifier: "Portrait", for: indexPath)
            if let cell = cell as? PortraitTableViewCell {
                cell.delegate = self
            }
        case Section.location.rawValue:
            switch indexPath.row {
            case 0:
                cell = tableView.dequeueReusableCell(withIdentifier: "Attribute", for: indexPath)
                if let cell = cell as? AttributeTableViewCell {
                    cell.delegate = self
                    cell.attribute = Patient.Keys.location
                    cell.attributeType = .string
                }
            default:
                cell = tableView.dequeueReusableCell(withIdentifier: "LatLng", for: indexPath)
                if let cell = cell as? LatLngTableViewCell {
                    cell.delegate = self
                }
            }
        case Section.observations.rawValue:
            cell = tableView.dequeueReusableCell(withIdentifier: "Observation", for: indexPath)
            if let cell = cell as? ObservationTableViewCell {
                cell.delegate = self
                cell.observationView.textView.returnKeyType = .done
            }
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "Attribute", for: indexPath)
            if let cell = cell as? AttributeTableViewCell {
                cell.delegate = self
                switch indexPath.section {
                case Section.info.rawValue:
                    cell.attribute = INFO[indexPath.row]
                    cell.attributeType = INFO_TYPES[indexPath.row]
                case Section.vitals.rawValue:
                    cell.attribute = VITALS[indexPath.row]
                    cell.attributeType = VITALS_TYPES[indexPath.row]
                default:
                    break
                }
            }
        }
        if let cell = cell as? PatientTableViewCell {
            cell.configure(from: patient)
            cell.isLast = indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1
        }
        return cell
    }
}
