//
//  PatientTableViewController.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

let INFO = ["firstName", "lastName", "complaint"]
let INFO_TYPES: [AttributeTableViewCellType] = [.string, .string, .string]

let VITALS = ["respiratoryRate", "triagePerfusion", "pulse", "capillaryRefill", "triageMentalStatus", "bloodPressure", "gcsTotal"]
let VITALS_TYPES: [AttributeTableViewCellType] = [.number, .triagePerfusion, .number, .number, .triageMentalStatus, .string, .number]

@objc protocol PatientTableViewControllerDelegate {
    @objc optional func patientTableViewControllerDidCancel(_ vc: PatientTableViewController)
    @objc optional func patientTableViewControllerDidSave(_ vc: PatientTableViewController)
    @objc optional func patientTableViewController(_ vc: PatientTableViewController, didUpdatePriority priority: Int)
}

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
class PatientTableViewController: UIViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate,
                                  FacilitiesTableViewControllerDelegate, ConfirmTransportViewControllerDelegate,
                                  AttributeTableViewCellDelegate, PatientTableViewControllerDelegate, PriorityTableViewCellDelegate,
                                  ObservationTableViewCellDelegate, RecordButtonDelegate {
    enum Section: Int, CaseIterable {
        case ageAndGender = 0
        case info
        case priority
        case vitals
        case location
        case observations
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var updateButtonBackgroundView: UIView!
    @IBOutlet weak var updateButton: RecordButton!

    private var inputToolbar: UIToolbar!

    weak var delegate: PatientTableViewControllerDelegate?

    var patient: Patient!
    var notificationToken: NotificationToken?

    deinit {
        removeKeyboardListener()
        notificationToken?.invalidate()
    }

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        addKeyboardListener()

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.bgBackground.withAlphaComponent(0).cgColor, UIColor.bgBackground.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 11.0 / updateButtonBackgroundView.frame.height)
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = updateButtonBackgroundView.bounds
        updateButtonBackgroundView.layer.insertSublayer(gradientLayer, at: 0)
        updateButtonBackgroundView.backgroundColor = .clear

        let prevItem = UIBarButtonItem(
            image: UIImage(named: "ChevronUp"), style: .plain, target: self, action: #selector(inputPrevPressed))
        prevItem.width = 44
        let nextItem = UIBarButtonItem(
            image: UIImage(named: "ChevronDown"), style: .plain, target: self, action: #selector(inputNextPressed))
        nextItem.width = 44
        inputToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
        inputToolbar.setItems([
            prevItem,
            nextItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(
                title: NSLocalizedString("InputAccessoryView.done", comment: ""), style: .plain, target: self,
                action: #selector(inputDonePressed))
        ], animated: false)

        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: "Attribute")
        tableView.register(LocationTableViewCell.self, forCellReuseIdentifier: "Location")
        tableView.register(ObservationTableViewCell.self, forCellReuseIdentifier: "Observation")
        tableView.register(PriorityTableViewCell.self, forCellReuseIdentifier: "Priority")
        tableView.register(SectionInfoTableViewCell.self, forCellReuseIdentifier: "Section")

        tableView.register(PatientTableViewFooterView.self, forHeaderFooterViewReuseIdentifier: "Footer")
        tableView.register(PatientTableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: "Header")

        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: updateButtonBackgroundView.frame.height, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        tableView.rowHeight = UITableView.automaticDimension

        if let tableHeaderView = tableView.tableHeaderView as? PatientHeaderView {
            tableHeaderView.configure(from: patient)
            tableHeaderView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableHeaderView.widthAnchor.constraint(equalTo: tableView.widthAnchor)
            ])
        }

        if patient.realm != nil {
            notificationToken = patient.observe { [weak self] (change) in
                self?.didObserveChange(change)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // hack to trigger appropriate autolayout for header view- assign again, then trigger a second layout of just the tableView
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.layoutIfNeeded()
        // update background gradient layer for button
        for layer in updateButtonBackgroundView.layer.sublayers ?? [] {
            if let layer = layer as? CAGradientLayer {
                layer.endPoint = CGPoint(x: 0.5, y: 11.0 / updateButtonBackgroundView.frame.height)
                layer.frame = updateButtonBackgroundView.bounds
            }
        }
    }

    @objc override func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
            UIView.animate(withDuration: duration) {
                var insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
                if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                    insets.bottom -= window.safeAreaInsets.bottom
                }
                self.tableView.contentInset = insets
                self.tableView.scrollIndicatorInsets = insets
            }
        }
    }

    @objc override func keyboardWillHide(_ notification: NSNotification) {
        UIView.animate(withDuration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25) {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.updateButtonBackgroundView.frame.height, right: 0)
            self.tableView.scrollIndicatorInsets = .zero
        }
    }

    override var inputAccessoryView: UIView? {
        return inputToolbar
    }

    @objc func inputPrevPressed() {
        for cell in tableView.visibleCells where cell.isFirstResponder {
            if let cell = cell as? AttributeTableViewCell, cell.focusPrev() {
                break
            }
            if var indexPath = tableView.indexPath(for: cell) {
                if indexPath.row > 0 {
                    indexPath.row -= 1
                } else if indexPath.section > 0 {
                    indexPath.section -= 1
                    indexPath.row = tableView.numberOfRows(inSection: indexPath.section) - 1
                } else {
                    break
                }
                if let cell = tableView.cellForRow(at: indexPath) as? AttributeTableViewCell {
                    if cell.focusPrev() {
                        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                        break
                    }
                }
            }
            cell.resignFirstResponder()
            break
        }
    }

    @objc func inputNextPressed() {
        for cell in tableView.visibleCells where cell.isFirstResponder {
            if let cell = cell as? AttributeTableViewCell, cell.focusNext() {
                break
            }
            if var indexPath = tableView.indexPath(for: cell) {
                if indexPath.row < (tableView.numberOfRows(inSection: indexPath.section) - 1) {
                    indexPath.row += 1
                } else if indexPath.section < (tableView.numberOfSections - 1) {
                    indexPath.section += 1
                    indexPath.row = 0
                } else {
                    break
                }
                if let cell = tableView.cellForRow(at: indexPath) as? AttributeTableViewCell {
                    if cell.focusNext() {
                        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                        break
                    }
                }
            }
            cell.resignFirstResponder()
            break
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
            vc.patient = Patient(clone: patient!)
            vc.startingOffsetY = tableView.contentOffset.y
        }
    }

    func didObserveChange(_ change: ObjectChange<Patient>) {
        switch change {
        case .change:
            if let tableViewHeader = tableView.tableHeaderView as? PatientHeaderView {
                tableViewHeader.configure(from: patient)
            }
            tableView.reloadData()
        case .error(let error):
            presentAlert(error: error)
        case .deleted:
            dismissAnimated()
        }
    }

    func cancelTransport() {
        let observation = Patient(clone: patient!)
        observation.parentId = patient.currentId
        observation.setTransported(false)
        save(patient: observation.changes(from: patient))
    }

    func save(patient: Patient) {
        AppRealm.createOrUpdatePatient(patient: patient)
    }

    // MARK: - AttributeTableViewCellDelegate

    func attributeTableViewCellDidPressAlert(_ cell: AttributeTableViewCell, for attribute: String, with type: String) {
        if attribute == Patient.Keys.location {
            if let lat = patient.lat, let lng = patient.lng, !lat.isEmpty, !lng.isEmpty {
                let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Map")
                if let vc = vc as? PatientMapViewController {
                    vc.patient = patient
                    presentAnimated(vc)
                }
            }
        }
    }

    // MARK: - ConfirmTransportViewControllerDelegate

    func confirmTransportViewControllerDidConfirm(_ vc: ConfirmTransportViewController, facility: Facility, agency: Agency) {
        let observation = Patient()
        observation.parentId = patient.currentId
        observation.setTransported(true)
        observation.transportFacility = facility
        observation.transportAgency = agency
        save(patient: observation)
    }

    // MARK: - FacilitiesTableViewControllerDelegate

    func facilitiesTableViewControllerDidConfirmLeavingIndependently(_ vc: FacilitiesTableViewController) {
        let observation = Patient()
        observation.parentId = patient.currentId
        observation.setTransported(true, isTransportedLeftIndependently: true)
        save(patient: observation)
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

    // MARK: - PatientTableViewControllerDelegate

    func patientTableViewControllerDidCancel(_ vc: PatientTableViewController) {
        if vc as? ObservationTableViewController != nil {
            tableView.setContentOffset(vc.tableView.contentOffset, animated: false)
            navigationController?.popViewController(animated: false)
        }
    }

    func patientTableViewController(_ vc: PatientTableViewController, didUpdatePriority priority: Int) {
        delegate?.patientTableViewController?(self, didUpdatePriority: priority)
    }

    func patientTableViewControllerDidSave(_ vc: PatientTableViewController) {
        navigationController?.popViewController(animated: false)
    }

    // MARK: - PriorityTableViewCellDelegate

    func priorityTableViewCell(_ cell: PriorityTableViewCell, didSelect priority: Int) {
        if priority != patient.priority.value, let priority = Priority(rawValue: priority) {
            let observation = Patient()
            observation.parentId = patient.currentId
            observation.setPriority(priority)
            save(patient: observation)
        }
    }

    func priorityTableViewCellDidPressCancelTransport(_ cell: PriorityTableViewCell) {
        let alert = UIAlertController(title: "PatientTableViewController.confirmCancelTransport.title".localized,
                                      message: "PatientTableViewController.confirmCancelTransport.message".localized,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Button.confirm".localized, style: .destructive, handler: { [weak self] (_) in
            guard let self = self else { return }
            self.cancelTransport()
        }))
        presentAnimated(alert)
    }

    func priorityTableViewCellDidPressTransport(_ cell: PriorityTableViewCell) {
        let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Facilities")
        if let vc = vc as? FacilitiesTableViewController {
            vc.patient = Patient(clone: patient!)
            let navVC = UINavigationController(rootViewController: vc)
            navVC.delegate = self
            navVC.navigationBar.isHidden = true
            presentAnimated(navVC)
        }
    }

    func priorityTableViewCellDidSetEditing(_ cell: PriorityTableViewCell) {
        tableView.beginUpdates()
        tableView.endUpdates()
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
        if section > Section.priority.rawValue {
            return 44
        }
        return 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section > Section.priority.rawValue {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header")
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section > Section.info.rawValue {
            return 15
        }
        return 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Footer")
        return view
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.location.rawValue:
            if patient.isTransported {
                return "PatientTableViewController.transport".localized
            } else {
                return "PatientTableViewController.location".localized
            }
        case Section.vitals.rawValue:
            return "PatientTableViewController.vitals".localized
        case Section.observations.rawValue:
            return "PatientTableViewController.observations".localized
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.ageAndGender.rawValue:
            return 1
        case Section.info.rawValue:
            return INFO.count
        case Section.priority.rawValue:
            return 1
        case Section.location.rawValue:
            return patient.isTransported ? (patient.isTransportedLeftIndependently ? 1 : 2) : 1
        case Section.vitals.rawValue:
            return VITALS.count
        case Section.observations.rawValue:
            return 1
        default:
            return 0
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case Section.ageAndGender.rawValue:
            cell = tableView.dequeueReusableCell(withIdentifier: "Attribute", for: indexPath)
            if let cell = cell as? AttributeTableViewCell {
                cell.delegate = self
                cell.attributes = [Patient.Keys.age, Patient.Keys.gender]
                cell.attributeTypes = [.age, .gender]
            }
        case Section.priority.rawValue:
            cell = tableView.dequeueReusableCell(withIdentifier: "Priority", for: indexPath)
            if let cell = cell as? PriorityTableViewCell {
                cell.delegate = self
            }
        case Section.location.rawValue:
            if patient.isTransported {
                if patient.isTransportedLeftIndependently {
                    cell = tableView.dequeueReusableCell(withIdentifier: "Section", for: indexPath)
                    if let cell = cell as? SectionInfoTableViewCell {
                        cell.button.isHidden = true
                        cell.label.text = "PatientTableViewController.transport.leftIndependently".localized
                    }
                } else {
                    cell = tableView.dequeueReusableCell(withIdentifier: "Attribute", for: indexPath)
                    if let cell = cell as? AttributeTableViewCell {
                        cell.delegate = self
                        switch indexPath.row {
                        case 0:
                            cell.attributes = [Patient.Keys.transportFacility]
                        case 1:
                            cell.attributes = [Patient.Keys.transportAgency]
                        default:
                            break
                        }
                        cell.attributeTypes = [.object]
                    }
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "Location", for: indexPath)
                if let cell = cell as? AttributeTableViewCell {
                    cell.delegate = self
                    cell.attributes = [Patient.Keys.location]
                    cell.attributeTypes = [.string]
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
                    cell.attributes = [INFO[indexPath.row]]
                    cell.attributeTypes = [INFO_TYPES[indexPath.row]]
                case Section.vitals.rawValue:
                    cell.attributes = [VITALS[indexPath.row]]
                    cell.attributeTypes = [VITALS_TYPES[indexPath.row]]
                default:
                    break
                }
            }
        }
        if let cell = cell as? BasePatientTableViewCell {
            cell.isEditing = isEditing
            cell.configure(from: patient)
        }
        return cell
    }
}
