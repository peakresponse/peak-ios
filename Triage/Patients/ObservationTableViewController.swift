//
//  ObservationTableViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import CoreLocation
import Speech
import UIKit

class ObservationTableViewController: PatientTableViewController, CLLocationManagerDelegate, PatientViewDelegate, RecordingViewControllerDelegate {
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    
    let dispatchGroup = DispatchGroup()
    var uploadTask: URLSessionTask?

    let locationManager = CLLocationManager()
    var cameraHelper = CameraHelper()
    var originalObservation: Observation!

    override func viewDidLoad() {
        super.viewDidLoad()

        /// make a copy of the observation object before editing for comparison
        originalObservation = patient.asObservation()

        if let tableHeaderView = tableView.tableHeaderView as? PatientTableHeaderView {
            tableHeaderView.patientView.cameraHelper = cameraHelper
            tableHeaderView.patientView.delegate = self
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !patient.hasLatLng {
            captureLocation()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        /// change editing state after layout prevents layout constraint warnings
        tableView.setEditing(true, animated: false)
    }
    
    @IBAction func cancelPressed() {
        delegate?.patientTableViewControllerDidCancel?(self)
    }

    @IBAction func savePressed(_ sender: Any) {
        if patient.priority.value == nil {
            presentAlert(title: "Error".localized, message: "Please select a SALT priority")
            return
        }

        let activityView = UIActivityIndicatorView(style: .medium)
        activityView.color = patient.priorityLabelColor
        activityView.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)

        let saveObservation = { [weak self] in
            guard let self = self, let observation = self.patient as? Observation else { return }
            AppRealm.createObservation(observation.changes(from: self.originalObservation)) { (observation, error) in
                let observationId = observation?.id
                DispatchQueue.main.async { [weak self] in
                    self?.navigationItem.rightBarButtonItem = self?.saveBarButtonItem
                    if let error = error {
                        self?.presentAlert(error: error)
                    } else if let self = self, let observationId = observationId {
                        let realm = AppRealm.open()
                        realm.refresh()
                        if let observation = realm.object(ofType: Observation.self, forPrimaryKey: observationId) {
                            self.delegate?.patientTableViewController?(self, didSave: observation)
                        }
                    }
                }
            }
        }

        if uploadTask != nil {
            dispatchGroup.notify(queue: DispatchQueue.main) {
                saveObservation()
            }
        } else {
            saveObservation()
        }
    }
    
    private func captureLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestLocation()
        if let cell = tableView.cellForRow(at: IndexPath(row: 3, section: Section.info.rawValue)) as? LocationTableViewCell {
            cell.setCapturing(true)
        }
    }

    private func extractValues(text: String) {
        var tokens = text.components(separatedBy: .whitespacesAndNewlines)
        var extracted: [String] = []
        var number: Int? = nil
        var guess: String? = nil
        while tokens.count > 0 {
            let token = tokens.removeFirst()
            let lower = token.lowercased()
            if lower.contains("priority") && !extracted.contains(Patient.Keys.priority) {
                guess = nil
                number = nil
                let colors = ["red", "yellow", "green", "gray", "black"]
                let priorities = ["immediate", "delayed", "minimal", "expectant", "deceased"]
                var priority: Int?
                if colors.contains(tokens.first?.lowercased() ?? "") {
                    let token = tokens.removeFirst()
                    priority = colors.firstIndex(of: token)
                } else if priorities.contains(tokens.first?.lowercased() ?? "") {
                    let token = tokens.removeFirst()
                    priority = priorities.firstIndex(of: token)
                }
                if let value = priority {
                    DispatchQueue.main.async { [weak self] in
                        self?.patient.priority.value = value
                        self?.tableView.reloadSections(IndexSet(arrayLiteral: 0, 1), with: .none)
                    }
                    extracted.append(Patient.Keys.priority)
                }
            } else if ["expectant", "deceased"].contains(lower) {
                guess = nil
                number = nil
                let value = lower == "expectant" ? 3 : 4
                DispatchQueue.main.async { [weak self] in
                    self?.patient.priority.value = value
                    self?.tableView.reloadSections(IndexSet(arrayLiteral: 0, 1), with: .none)
                }
                extracted.append(Patient.Keys.priority)
            } else if lower.contains("patient") && !extracted.contains(Patient.Keys.firstName) {
                guess = nil
                number = nil
                while ["name", "is"].contains(tokens.first?.lowercased() ?? "") {
                    _ = tokens.removeFirst()
                    guess = Patient.Keys.firstName
                }
            } else if lower.contains("age") && !extracted.contains(Patient.Keys.age) {
                guess = Patient.Keys.age
                number = nil
            } else if lower.contains("year") && !extracted.contains(Patient.Keys.age) {
                guess = nil
                if tokens.first?.lowercased().contains("old") ?? false {
                    _ = tokens.removeFirst()
                    if let value = number {
                        DispatchQueue.main.async { [weak self] in
                            self?.patient.age.value = value
                            self?.tableView.reloadRows(at: [IndexPath(row: 2, section: Section.info.rawValue)], with: .none)
                        }
                        extracted.append(Patient.Keys.age)
                    }
                }
                number = nil
            } else if lower.contains("blood") && !extracted.contains(Patient.Keys.bloodPressure) {
                guess = nil
                number = nil
                if tokens.first?.lowercased().contains("pressure") ?? false {
                    _ = tokens.removeFirst()
                    guess = Patient.Keys.bloodPressure
                }
            } else if lower.contains("bp") && !extracted.contains(Patient.Keys.bloodPressure) {
                guess = Patient.Keys.bloodPressure
                number = nil
            } else if lower.contains("capillary") && !extracted.contains(Patient.Keys.capillaryRefill) {
                guess = nil
                number = nil
                if tokens.first?.lowercased().contains("refill") ?? false {
                    _ = tokens.removeFirst()
                    guess = Patient.Keys.capillaryRefill
                }
            } else if lower.contains("respiratory") && !extracted.contains(Patient.Keys.respiratoryRate) {
                guess = nil
                number = nil
                if tokens.first?.lowercased().contains("rate") ?? false {
                    _ = tokens.removeFirst()
                    guess = Patient.Keys.respiratoryRate
                }
            } else if lower.contains("pulse") && !extracted.contains(Patient.Keys.pulse) {
                guess = Patient.Keys.pulse
                number = nil
            } else if lower.range(of: #"\d+/\d+"#, options: .regularExpression) != nil {
                if guess == Patient.Keys.bloodPressure {
                    DispatchQueue.main.async { [weak self] in
                        self?.patient.bloodPressure = lower
                        self?.tableView.reloadRows(at: [IndexPath(row: 3, section: Section.vitals.rawValue)], with: .none)
                    }
                    extracted.append(Patient.Keys.bloodPressure)
                }
                guess = nil
                number = nil
            } else if let value = Int(lower) {
                number = nil
                switch guess {
                case .some(Patient.Keys.age):
                    DispatchQueue.main.async { [weak self] in
                        self?.patient.age.value = value
                        self?.tableView.reloadRows(at: [IndexPath(row: 2, section: Section.info.rawValue)], with: .none)
                    }
                    extracted.append(Patient.Keys.age)
                case .some(Patient.Keys.respiratoryRate):
                    DispatchQueue.main.async { [weak self] in
                        self?.patient.respiratoryRate.value = value
                        self?.tableView.reloadRows(at: [IndexPath(row: 0, section: Section.vitals.rawValue)], with: .none)
                    }
                    guess = nil
                    extracted.append(Patient.Keys.respiratoryRate)
                case .some(Patient.Keys.pulse):
                    DispatchQueue.main.async { [weak self] in
                        self?.patient.pulse.value = value
                        self?.tableView.reloadRows(at: [IndexPath(row: 1, section: Section.vitals.rawValue)], with: .none)
                    }
                    guess = nil
                    extracted.append(Patient.Keys.pulse)
                case .some(Patient.Keys.capillaryRefill):
                    DispatchQueue.main.async { [weak self] in
                        self?.patient.capillaryRefill.value = value
                        self?.tableView.reloadRows(at: [IndexPath(row: 2, section: Section.vitals.rawValue)], with: .none)
                    }
                    guess = nil
                    extracted.append(Patient.Keys.capillaryRefill)
                default:
                    number = value
                }
            } else if ["is"].contains(token) {
                continue
            } else {
                number = nil
                if guess == Patient.Keys.firstName {
                    DispatchQueue.main.async { [weak self] in
                        self?.patient.firstName = token
                        self?.tableView.reloadRows(at: [IndexPath(row: 0, section: Section.info.rawValue)], with: .none)
                    }
                    guess = Patient.Keys.lastName
                    extracted.append(Patient.Keys.firstName)
                } else if guess == Patient.Keys.lastName {
                    DispatchQueue.main.async { [weak self] in
                        self?.patient.lastName = token
                        self?.tableView.reloadRows(at: [IndexPath(row: 1, section: Section.info.rawValue)], with: .none)
                    }
                    guess = nil
                    extracted.append(Patient.Keys.lastName)
                } else {
                    guess = nil
                }
            }
        }
    }

    @IBAction override func updatePressed() {
        performSegue(withIdentifier: "Record", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? RecordingViewController {
            vc.delegate = self
        }
    }
    
    // MARK: - AttributeTableViewCellDelegate

    func attributeTableViewCell(_ cell: AttributeTableViewCell, didChange text: String) {
        if cell.attributeType == .object {
            if text.isEmpty {
                patient.setValue(nil, forKey: cell.attribute)
            }
        } else {
            patient.setValue(text, forKey: cell.attribute)
            if cell.attribute == Patient.Keys.location, text.isEmpty {
                patient.clearLatLng()
                cell.configure(from: patient)
            }
        }
        if cell.attribute == Patient.Keys.transportAgency || cell.attribute == Patient.Keys.transportFacility {
            tableView.reloadSections(IndexSet([Section.info.rawValue]), with: .none)
        }
    }
    
    override func attributeTableViewCellDidPressAlert(_ cell: AttributeTableViewCell) {
        if cell as? LocationTableViewCell != nil {
            if !patient.hasLatLng {
                captureLocation()
                return
            }
        }
        super.attributeTableViewCellDidPressAlert(cell)
    }

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
    
    // MARK: - ConfirmTransportViewControllerDelegate

    override func confirmTransportViewControllerDidConfirm(_ vc: ConfirmTransportViewController, facility: Facility, agency: Agency) {
        patient.priority.value = Priority.transported.rawValue
        patient.transportFacility = facility
        patient.transportAgency = agency
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .none)
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .none)
        if let tableViewHeader = tableView.tableHeaderView as? PatientTableHeaderView {
            tableViewHeader.configure(from: patient)
        }
        delegate?.patientTableViewController?(self, didUpdatePriority: Priority.transported.rawValue)
    }

    // MARK: - FacilitiesTableViewControllerDelegate

    override func facilitiesTableViewControllerDidConfirmLeavingIndependently(_ vc: FacilitiesTableViewController) {
        patient.priority.value = Priority.transported.rawValue
        patient.transportFacility = nil
        patient.transportAgency = nil
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .none)
        if let tableViewHeader = tableView.tableHeaderView as? PatientTableHeaderView {
            tableViewHeader.configure(from: patient)
        }
        delegate?.patientTableViewController?(self, didUpdatePriority: Priority.transported.rawValue)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            patient.lat = String(format: "%.6f", location.coordinate.latitude)
            patient.lng = String(format: "%.6f", location.coordinate.longitude)
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 3, section: Section.info.rawValue)) as? LocationTableViewCell {
            cell.configure(from: patient)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }

    // MARK: - PatientViewDelegate

    func patientView(_ patientView: PatientView, didCapturePhoto fileURL: URL, withImage image: UIImage) {
        dispatchGroup.enter()
        uploadTask = ApiClient.shared.upload(fileURL: fileURL) { [weak self] (response, error) in
            if let error = error {
                print(error)
            } else if let response = response, let signedId = response["signed_id"] as? String {
                self?.patient.portraitUrl = signedId
                AppCache.cache(fileURL: fileURL, filename: signedId)
            }
            self?.dispatchGroup.leave()
        }
        uploadTask?.resume()
    }

    // MARK: - PriorityViewDelegate

    override func priorityViewDidDismiss(_ view: PriorityView) {
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.layoutIfNeeded()
        tableView.reloadData()
    }
    
    override func priorityView(_ view: PriorityView, didSelect priority: Int) {
        patient.priority.value = priority
        if let tableViewHeader = tableView.tableHeaderView as? PatientTableHeaderView {
            tableViewHeader.configure(from: patient)
        }
        delegate?.patientTableViewController?(self, didUpdatePriority: priority)
        priorityViewDidDismiss(view)
    }

    // MARK: - RecordingViewControllerDelegate

    func recordingViewController(_ vc: RecordingViewController, didRecognizeText text: String) {
        patient.text = text
        tableView.reloadSections(IndexSet(integer: Section.observations.rawValue), with: .none)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.extractValues(text: text)
        }
    }

    func recordingViewController(_ vc: RecordingViewController, didFinishRecording fileURL: URL) {
        /// start upload
        dispatchGroup.enter()
        uploadTask = ApiClient.shared.upload(fileURL: fileURL) { [weak self] (response, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                } else if let response = response, let signedId = response["signed_id"] as? String {
                    AppCache.cache(fileURL: fileURL, filename: signedId)
                    self.patient.audioUrl = signedId
                    self.tableView.reloadSections(IndexSet(integer: Section.observations.rawValue), with: .none)
                }
                self.dispatchGroup.leave()
            }
        }
        uploadTask?.resume()
        /// hide the record button, user must clear current recording to continue
        updateButton.isHidden = true
    }

    func recordingViewController(_ vc: RecordingViewController, didThrowError error: Error) {
        switch error {
        case AudioHelperError.speechRecognitionNotAuthorized:
            /// even with speech recognition off, we can still allow a recording...
            vc.startRecording()
        default:
            dismiss(animated: true) { [weak self] in
                self?.presentAlert(error: error)
            }
        }
    }
    
    // MARK: - ObservationTableViewCellDelegate

    func observationTableViewCell(_ cell: ObservationTableViewCell, didChange text: String) {
        patient.text = text
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func observationTableViewCellDidReturn(_ cell: ObservationTableViewCell) {
        _ = cell.resignFirstResponder()
    }
    
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        switch indexPath.section {
//        case Section.location.rawValue:
//            if patient.isTransported {
//                if indexPath.row == 0 {
//                    if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(identifier: "Agencies") as? AgenciesTableViewController,
//                        let observation = patient as? Observation {
//                        vc.observation = observation
//                        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "CANCEL".localized, style: .plain, target: self, action: #selector(dismissAnimated))
//                        vc.handler = { [weak self] (vc) in
//                            guard let self = self else { return }
//                            self.dismiss(animated: true) { [weak self] in
//                                guard let self = self else { return }
//                                self.tableView.reloadSections(IndexSet([Section.location.rawValue]), with: .none)
//                            }
//                        }
//                        let navVC = UINavigationController(rootViewController: vc)
//                        presentAnimated(navVC)
//                    }
//                } else if indexPath.row == 1 {
//                    if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(identifier: "Facilities") as? FacilitiesTableViewController,
//                        let observation = patient as? Observation {
//                        vc.observation = observation
//                        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "CANCEL".localized, style: .plain, target: self, action: #selector(dismissAnimated))
//                        vc.handler = { [weak self] (vc) in
//                            guard let self = self else { return }
//                            self.dismiss(animated: true) { [weak self] in
//                                guard let self = self else { return }
//                                self.tableView.reloadSections(IndexSet([Section.location.rawValue]), with: .none)
//                            }
//                        }
//                        let navVC = UINavigationController(rootViewController: vc)
//                        presentAnimated(navVC)
//                    }
//                }
//            } else {
//                if indexPath.row == 1 {
//                    if let lat = patient.lat, let lng = patient.lng, lat != "", lng != "" {
//                        if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Map") as? PatientMapViewController {
//                            vc.patient = patient
//                            navigationController?.pushViewController(vc, animated: true)
//                        }
//                    }
//                }
//            }
//        default:
//            super.tableView(tableView, didSelectRowAt: indexPath)
//        }
//    }
}
