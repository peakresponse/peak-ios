//
//  ObservationTableViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import Speech
import UIKit

@objc protocol ObservationTableViewControllerDelegate {
    @objc optional func observationTableViewController(_ vc: ObservationTableViewController, didSave observation: Observation)
}

class ObservationTableViewController: PatientTableViewController, PatientViewDelegate, RecorderViewDelegate {
    weak var delegate: ObservationTableViewControllerDelegate?
    
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!

    let dispatchGroup = DispatchGroup()
    var uploadTask: URLSessionTask?

    var cameraHelper = CameraHelper()
    var recorderView: RecorderView?
    
    var bluetoothButton: Button!

    var originalObservation: Observation!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /// make a copy of the observation object before editing for comparison
        originalObservation = patient.asObservation()

        updateButton.setTitle(NSLocalizedString("RECORD", comment: ""), for: .normal)
        updateButton.setImage(UIImage(named: "Microphone"), for: .normal)
        updateButton.removeTarget(self, action: #selector(updatePressed(_:)), for: .touchUpInside)
        updateButton.addTarget(self, action: #selector(recordPressed(_:)), for: .touchUpInside)

        bluetoothButton = Button(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        bluetoothButton.translatesAutoresizingMaskIntoConstraints = false
        bluetoothButton.backgroundColor = .gray3
        bluetoothButton.selectedColor = .natBlue
        bluetoothButton.tintColor = .white
        bluetoothButton.adjustsImageWhenHighlighted = false
        bluetoothButton.titleLabel?.font = UIFont(name: "NunitoSans-SemiBold", size: 18)
        bluetoothButton.setImage(UIImage(named: "Bluetooth"), for: .normal)
        bluetoothButton.addTarget(self, action: #selector(bluetoothPressed(_:)), for: .touchUpInside)
        
        tableView.allowsSelectionDuringEditing = true
        tableView.setEditing(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bluetoothButton.removeFromSuperview()
        if AudioHelper.bluetoothHFPInputs.count > 0 {
            if let superview = tableView.superview {
                superview.addSubview(bluetoothButton)
                NSLayoutConstraint.activate([
                    bluetoothButton.widthAnchor.constraint(equalToConstant: 44),
                    bluetoothButton.heightAnchor.constraint(equalToConstant: 44),
                    bluetoothButton.trailingAnchor.constraint(equalTo: updateButton.leadingAnchor, constant: -20),
                    bluetoothButton.centerYAnchor.constraint(equalTo: updateButton.centerYAnchor)
                ])
                bluetoothButton.isHidden = updateButton.isHidden
                bluetoothButton.isSelected = AppSettings.audioInputPortUID != nil
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !patient.hasLatLng, let cell = tableView.cellForRow(at: IndexPath(row: 1, section: Section.location.rawValue)) as? LatLngTableViewCell {
            cell.captureLocation()
        }
    }

    @objc func bluetoothPressed(_ sender: Any) {
        if AppSettings.audioInputPortUID != nil {
            /// toggle Bluetooth off
            AppSettings.audioInputPortUID = nil
        } else {
            /// select Bluetooth input, provide prompt if multiple
            let inputPorts = AudioHelper.bluetoothHFPInputs
            if inputPorts.count > 1 {
                let alert = UIAlertController(title: NSLocalizedString("Select Bluetooth Input", comment: ""), message: nil, preferredStyle: .actionSheet)
                for inputPort in inputPorts {
                    alert.addAction(UIAlertAction(title: inputPort.portName, style: .default, handler: { [weak self] (action) in
                        AppSettings.audioInputPortUID = inputPort.uid
                        self?.bluetoothButton.isSelected = true
                    }))
                }
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                presentAnimated(alert)
            } else {
                AppSettings.audioInputPortUID = inputPorts[0].uid
            }
        }
        bluetoothButton.isSelected = AppSettings.audioInputPortUID != nil
    }
    
    @IBAction func savePressed(_ sender: Any) {
        if patient.priority.value == nil {
            presentAlert(title: NSLocalizedString("Error", comment: ""), message: "Please select a SALT priority")
            return
        }
        
        let activityView = UIActivityIndicatorView(style: .medium)
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
                            self.delegate?.observationTableViewController?(self, didSave: observation)
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

    @IBAction func recordPressed(_ sender: Any) {
        if let superview = tableView.superview {
            /// show recorder
            let recorderView = RecorderView(frame: .zero)
            recorderView.delegate = self
            recorderView.translatesAutoresizingMaskIntoConstraints = false
            superview.addSubview(recorderView)
            NSLayoutConstraint.activate([
                recorderView.topAnchor.constraint(equalTo: superview.topAnchor),
                recorderView.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
                recorderView.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                recorderView.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            ])
            recorderView.show()
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
        }
        if cell.attribute == Patient.Keys.transportAgency || cell.attribute == Patient.Keys.transportFacility {
            tableView.reloadSections(IndexSet([Section.location.rawValue]), with: .none)
        }
    }

    func attributeTableViewCellDidSelect(_ cell: AttributeTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            if indexPath.section == Section.location.rawValue {
                tableView(tableView, didSelectRowAt: indexPath)
            }
        }
    }
    
    // MARK: - LatLngTableViewCellDelegate
    
    func latLngTableViewCellDidClear(_ cell: LatLngTableViewCell) {
        patient.lat = ""
        patient.lng = ""
    }
    
    func latLngTableViewCell(_ cell: LatLngTableViewCell, didCapture lat: String, lng: String) {
        patient.lat = lat
        patient.lng = lng
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

    // MARK: - PortraitTableViewCellDelegate

    override func portaitTableViewCellDidPressTransportButton(_ cell: PortraitTableViewCell) {
        if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(identifier: "Facilities") as? FacilitiesTableViewController,
            let observation = patient as? Observation {
            vc.observation = observation
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("CANCEL", comment: ""), style: .plain, target: self, action: #selector(dismissAnimated))
            vc.handler = { [weak self] (vc) in
                guard let self = self else { return }
                if let nextVC = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(identifier: "Agencies") as? AgenciesTableViewController {
                    nextVC.observation = observation
                    nextVC.handler = { [weak self] (vc) in
                        guard let self = self else { return }
                        self.dismiss(animated: true) { [weak self] in
                            guard let self = self else { return }
                            self.tableView.reloadSections(IndexSet([Section.location.rawValue]), with: .none)
                        }
                    }
                    vc.navigationController?.pushViewController(nextVC, animated: true)
                }
            }
            let navVC = UINavigationController(rootViewController: vc)
            presentAnimated(navVC)
        }
    }

    // MARK: - PriorityViewDelegate
    
    override func priorityView(_ view: PriorityView, didSelect priority: Int) {
        patient.priority.value = priority
        tableView.reloadSections(IndexSet(arrayLiteral: 0, 1), with: .none)
    }

    // MARK: - RecorderViewDelegate

    func recorderViewDidShow(_ view: RecorderView) {
        /// disable tableview and modal presentation interaction so that recording does not get interrupted by accidental swipe movement
        tableView.isUserInteractionEnabled = false
        if let recognizers = navigationController?.presentationController?.presentedView?.gestureRecognizers {
            for recognizer in recognizers {
                recognizer.isEnabled = false
            }
        }

        /// disable navigation items
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func recorderView(_ view: RecorderView, didRecognizeText text: String) {
        patient.text = text
        tableView.reloadSections(IndexSet(integer: Section.observations.rawValue), with: .none)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.extractValues(text: text)
        }
    }

    func recorderView(_ view: RecorderView, didFinishRecording fileURL: URL) {
        // start upload
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
    }
    
    func recorderViewDidDismiss(_ view: RecorderView) {
        /// re-enable tableview and model presentation interaction
        tableView.isUserInteractionEnabled = true
        if let recognizers = navigationController?.presentationController?.presentedView?.gestureRecognizers {
            for recognizer in recognizers {
                recognizer.isEnabled = true
            }
        }
        
        /// re-enable navigation items
        navigationItem.leftBarButtonItem?.isEnabled = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        /// hide the record button, user must clear current recording to continue
        updateButton.isHidden = true
        bluetoothButton.isHidden = true
    }

    func recorderView(_ recorderView: RecorderView, didThrowError error: Error) {
        switch error {
        case AudioHelperError.speechRecognitionNotAuthorized:
            /// even with speech recognition off, we can still allow a recording...
            recorderView.startRecording()
        default:
            recorderView.hide()
            presentAlert(error: error)
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

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
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
            if patient.isTransported {
                if indexPath.row == 0 {
                    if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(identifier: "Agencies") as? AgenciesTableViewController,
                        let observation = patient as? Observation {
                        vc.observation = observation
                        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("CANCEL", comment: ""), style: .plain, target: self, action: #selector(dismissAnimated))
                        vc.handler = { [weak self] (vc) in
                            guard let self = self else { return }
                            self.dismiss(animated: true) { [weak self] in
                                guard let self = self else { return }
                                self.tableView.reloadSections(IndexSet([Section.location.rawValue]), with: .none)
                            }
                        }
                        let navVC = UINavigationController(rootViewController: vc)
                        presentAnimated(navVC)
                    }
                } else if indexPath.row == 1 {
                    if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(identifier: "Facilities") as? FacilitiesTableViewController,
                        let observation = patient as? Observation {
                        vc.observation = observation
                        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("CANCEL", comment: ""), style: .plain, target: self, action: #selector(dismissAnimated))
                        vc.handler = { [weak self] (vc) in
                            guard let self = self else { return }
                            self.dismiss(animated: true) { [weak self] in
                                guard let self = self else { return }
                                self.tableView.reloadSections(IndexSet([Section.location.rawValue]), with: .none)
                            }
                        }
                        let navVC = UINavigationController(rootViewController: vc)
                        presentAnimated(navVC)
                    }
                }
            } else {
                if indexPath.row == 1 {
                    if let lat = patient.lat, let lng = patient.lng, lat != "", lng != "" {
                        if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Map") as? PatientMapViewController {
                            vc.patient = patient
                            navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        default:
            super.tableView(tableView, didSelectRowAt: indexPath)
        }
    }

    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let cell = cell as? PatientTableViewCell {
            if let cell = cell as? PortraitTableViewCell {
                cell.patientView.cameraHelper = cameraHelper
                cell.patientView.delegate = self
            }
        }
        return cell
    }
}
