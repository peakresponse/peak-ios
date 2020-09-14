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

@objc protocol PatientTableViewControllerDelegate {
    @objc optional func patientTableViewControllerDidCancel(_ vc: PatientTableViewController)
    @objc optional func patientTableViewControllerDidSave(_ vc: PatientTableViewController)
    @objc optional func patientTableViewController(_ vc: PatientTableViewController, didUpdatePriority priority: Int)
}

class PatientTableViewController: UIViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, FacilitiesTableViewControllerDelegate, ConfirmTransportViewControllerDelegate, AttributeTableViewCellDelegate, PatientTableViewControllerDelegate, PatientTableHeaderViewDelegate, ObservationTableViewCellDelegate, RecordButtonDelegate {
    enum Section: Int, CaseIterable {
        case info = 0
        case vitals
        case observations
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var updateButton: RecordButton!

    private var inputToolbar: UIToolbar!

    weak var delegate: PatientTableViewControllerDelegate?
    
    var patient: Patient!
    var notificationToken: NotificationToken?
    
    deinit {
        notificationToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let prevItem = UIBarButtonItem(image: UIImage(named: "ChevronUp"), style: .plain, target: self, action: #selector(inputPrevPressed))
        prevItem.width = 44
        let nextItem = UIBarButtonItem(image: UIImage(named: "ChevronDown"), style: .plain, target: self, action: #selector(inputNextPressed))
        nextItem.width = 44
        inputToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
        inputToolbar.setItems([
            prevItem,
            nextItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: NSLocalizedString("InputAccessoryView.done", comment: ""), style: .plain, target: self, action: #selector(inputDonePressed))
        ], animated: false)

        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: "Attribute")
        tableView.register(LocationTableViewCell.self, forCellReuseIdentifier: "Location")
        tableView.register(ObservationTableViewCell.self, forCellReuseIdentifier: "Observation")
        tableView.register(TableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: "Header")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Footer")

        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 85, right: 0)
        tableView.rowHeight = UITableView.automaticDimension

        if let tableHeaderView = tableView.tableHeaderView as? PatientTableHeaderView {
            tableHeaderView.configure(from: patient)
            tableHeaderView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableHeaderView.widthAnchor.constraint(equalTo: tableView.widthAnchor)
            ])
        }

        if patient.id != nil {
            notificationToken = patient.observe { [weak self] (change) in
                self?.didObserveChange(change)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        /// hack to trigger appropriate autolayout for header view- assign again, then trigger a second layout of just the tableView
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let defaultNotificationCenter = NotificationCenter.default
        defaultNotificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        defaultNotificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            UIView.animate(withDuration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25) {
                var insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
                if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                    insets.bottom -= window.safeAreaInsets.bottom
                }
                self.tableView.contentInset = insets
                self.tableView.scrollIndicatorInsets = insets
            }
        }
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        UIView.animate(withDuration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25) {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 85, right: 0)
            self.tableView.scrollIndicatorInsets = .zero
        }
    }

    override var inputAccessoryView: UIView? {
        return inputToolbar
    }
    
    @objc func inputPrevPressed() {
        for cell in tableView.visibleCells {
            if cell.resignFirstResponder() {
                if var indexPath = tableView.indexPath(for: cell) {
                    if indexPath.row > 0 {
                        indexPath.row -= 1
                    } else if indexPath.section > 0 {
                        indexPath.section -= 1
                        indexPath.row = tableView.numberOfRows(inSection: indexPath.section) - 1
                    } else {
                        break
                    }
                    if let cell = tableView.cellForRow(at: indexPath) {
                        if cell.becomeFirstResponder() {
                            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                        }
                    }
                }
                break
            }
        }
    }

    @objc func inputNextPressed() {
        for cell in tableView.visibleCells {
            if cell.resignFirstResponder() {
                if var indexPath = tableView.indexPath(for: cell) {
                    if indexPath.row < (tableView.numberOfRows(inSection: indexPath.section) - 1) {
                        indexPath.row += 1
                    } else if indexPath.section < (tableView.numberOfSections - 1) {
                        indexPath.section += 1
                        indexPath.row = 0
                    } else {
                        break
                    }
                    if let cell = tableView.cellForRow(at: indexPath) {
                        if cell.becomeFirstResponder() {
                            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                        }
                    }
                }
                break
            }
        }
    }

    @objc func inputDonePressed() {
        for cell in tableView.visibleCells {
            if cell.resignFirstResponder() {
                return
            }
        }
    }

    @IBAction func updatePressed() {
        performSegue(withIdentifier: "EditPatient", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ObservationTableViewController {
            vc.delegate = self
            vc.patient = patient.asObservation()
            vc.patient.version.value = (vc.patient.version.value ?? 0) + 1
        }
    }

    func didObserveChange(_ change: ObjectChange<Patient>) {
        switch change {
        case .change(_, _):
            if let tableViewHeader = tableView.tableHeaderView as? PatientTableHeaderView {
                tableViewHeader.configure(from: patient)
            }
            tableView.reloadData()
        case .error(let error):
            presentAlert(error: error)
        case .deleted:
            dismissAnimated()
        }
    }

    func save(observation: Observation) {
        AppRealm.createOrUpdatePatient(observation: observation) { [weak self] (patient, error) in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error: error)
                }
            }
        }
}

    // MARK: - AttributeTableViewCellDelegate

    func attributeTableViewCellDidPressAlert(_ cell: AttributeTableViewCell) {
        if cell.attribute == Patient.Keys.location {
            if let lat = patient.lat, let lng = patient.lng, !lat.isEmpty, !lng.isEmpty {
                if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Map") as? PatientMapViewController {
                    vc.patient = patient
                    presentAnimated(vc)
                }
            }
        }
    }
    
    // MARK: - ConfirmTransportViewControllerDelegate

    func confirmTransportViewControllerDidConfirm(_ vc: ConfirmTransportViewController, facility: Facility, agency: Agency) {
        let observation = Observation()
        observation.pin = patient.pin
        observation.priority.value = Priority.transported.rawValue
        observation.transportFacility = facility
        observation.transportAgency = agency
        save(observation: observation)
    }

    // MARK: - FacilitiesTableViewControllerDelegate
    
    func facilitiesTableViewControllerDidConfirmLeavingIndependently(_ vc: FacilitiesTableViewController) {
        let observation = Observation()
        observation.pin = patient.pin
        observation.priority.value = Priority.transported.rawValue
        observation.transportFacility = nil
        observation.transportAgency = nil
        save(observation: observation)
    }

    // MARK: - UINavigationControllerDelegate
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if let vc = viewController as? ConfirmTransportViewController {
            vc.delegate = self
        } else if let vc = viewController as? FacilitiesTableViewController {
            vc.delegate = self
        }
    }

    // MARK: - ObservationTableViewCellDelegate

    func observationTableViewCell(_ cell: ObservationTableViewCell, didThrowError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.presentAlert(error: error)
        }
    }
    
    // MARK: - PatientTableHeaderViewDelegate

    func patientTableHeaderView(_ view: PatientTableHeaderView, didPressStatusButton button: FormButton) {
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.layoutIfNeeded()
    }

    func patientTableHeaderView(_ view: PatientTableHeaderView, didPressTransportButton button: FormButton) {
        if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(identifier: "Facilities") as? FacilitiesTableViewController {
            vc.observation = patient.asObservation()
            let navVC = UINavigationController(rootViewController: vc)
            navVC.delegate = self
            navVC.navigationBar.isHidden = true
            presentAnimated(navVC)
        }
    }
    

    // MARK: - PatientTableViewControllerDelegate
    
    func patientTableViewControllerDidCancel(_ vc: PatientTableViewController) {
        if vc as? ObservationTableViewController != nil {
            navigationController?.popViewController(animated: false)
        }
    }

    func patientTableViewController(_ vc: PatientTableViewController, didUpdatePriority priority: Int) {
        delegate?.patientTableViewController?(self, didUpdatePriority: priority)
    }
    
    func patientTableViewControllerDidSave(_ vc: PatientTableViewController) {
        navigationController?.popViewController(animated: false)
    }
    
    // MARK: - PriorityViewDelegate

    func priorityViewDidDismiss(_ view: PriorityView) {
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.layoutIfNeeded()
        tableView.reloadData()
    }
    
    func priorityView(_ view: PriorityView, didSelect priority: Int) {
        let observation = Observation()
        observation.sceneId = patient.sceneId
        observation.pin = patient.pin
        observation.version.value = (patient.version.value ?? 0) + 1
        observation.priority.value = priority
        save(observation: observation)
    }

    // MARK: - RecordButtonDelegate
    
    func recordButton(_ button: RecordButton, willPresent alert: UIAlertController) -> UIViewController {
        return self
    }
    
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Section.observations.rawValue:
            if let text = patient.text {
                return ObservationTableViewCell.heightForText(text, width: tableView.frame.width)
            }
            fallthrough
        default:
            return tableView.rowHeight
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header")
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 15
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Footer")
        view?.backgroundView = UIView()
        return view
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.info.rawValue:
            return "Info".localized
        case Section.vitals.rawValue:
            return "Vitals".localized
        case Section.observations.rawValue:
            return "Observation".localized
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.info.rawValue:
            return INFO.count + (patient.isTransported ? 2 : 1)
        case Section.vitals.rawValue:
            return VITALS.count
        case Section.observations.rawValue:
            return 1
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case Section.observations.rawValue:
            cell = tableView.dequeueReusableCell(withIdentifier: "Observation", for: indexPath)
            if let cell = cell as? ObservationTableViewCell {
                cell.delegate = self
                cell.observationView.textView.returnKeyType = .done
            }
        case Section.info.rawValue:
            let index = indexPath.row - INFO.count
            if index >= 0 {
                if patient.isTransported {
                    switch index {
                    case 0:
                        cell = tableView.dequeueReusableCell(withIdentifier: "Attribute", for: indexPath)
                        if let cell = cell as? AttributeTableViewCell {
                            cell.delegate = self
                            cell.attribute = Patient.Keys.transportAgency
                            cell.attributeType = .object
                        }
                    default:
                        cell = tableView.dequeueReusableCell(withIdentifier: "Attribute", for: indexPath)
                        if let cell = cell as? AttributeTableViewCell {
                            cell.delegate = self
                            cell.attribute = Patient.Keys.transportFacility
                            cell.attributeType = .object
                        }
                    }
                } else {
                    cell = tableView.dequeueReusableCell(withIdentifier: "Location", for: indexPath)
                    if let cell = cell as? AttributeTableViewCell {
                        cell.delegate = self
                        cell.attribute = Patient.Keys.location
                        cell.attributeType = .string
                    }
                }
                break
            }
            fallthrough
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
        }
        return cell
    }
}
