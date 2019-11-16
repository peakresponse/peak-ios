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
    @objc optional func observationTableViewControllerDidDismiss(_ vc: ObservationTableViewController)
    @objc optional func observationTableViewController(_ vc: ObservationTableViewController, didSave observation: Observation)
}

class ObservationTableViewController: PatientTableViewController, PatientViewDelegate {
    weak var delegate: ObservationTableViewControllerDelegate?
    
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!

    let dispatchGroup = DispatchGroup()
    var observation: Observation!
    var uploadTask: URLSessionTask?

    var cameraHelper = CameraHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if title == "" {
            title = NSLocalizedString("New Patient", comment: "")
        }
        observation = patient.asObservation()
        if let audioHelper = audioHelper {
            audioHelper.reset()
        } else {
            audioHelper = AudioHelper()
        }
        
        tableView.setEditing(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !patient.hasLatLng, let cell = tableView.cellForRow(at: IndexPath(row: 1, section: Section.location.rawValue)) as? LatLngTableViewCell {
            cell.captureLocation()
        }
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        delegate?.observationTableViewControllerDidDismiss?(self)
    }
    
    @IBAction func savePressed(_ sender: Any) {
        if observation.priority.value == nil {
            presentAlert(title: NSLocalizedString("Error", comment: ""), message: "Please select a SALT priority")
            return
        }
        
        let index = toolbarItems?.firstIndex(of: saveBarButtonItem)
        if let index = index {
            let activityView = UIActivityIndicatorView(style: .medium)
            activityView.startAnimating()
            toolbarItems?[index] = UIBarButtonItem(customView: activityView)
        }

        let saveObservation = { [weak self] in
            guard let self = self else { return }
            AppRealm.createObservation(self.observation) { (observation, error) in
                let observationId = observation?.id
                DispatchQueue.main.async { [weak self] in
                    if let index = index, let saveBarButtonItem = self?.saveBarButtonItem {
                        self?.toolbarItems?[index] = saveBarButtonItem
                    }
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
                        self?.observation.priority.value = value
                        self?.tableView.reloadSections(IndexSet(arrayLiteral: 0, 1), with: .none)
                    }
                    extracted.append(Patient.Keys.priority)
                }
            } else if ["expectant", "deceased"].contains(lower) {
                guess = nil
                number = nil
                let value = lower == "expectant" ? 3 : 4
                DispatchQueue.main.async { [weak self] in
                    self?.observation.priority.value = value
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
                            self?.observation.age.value = value
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
                        self?.observation.bloodPressure = lower
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
                        self?.observation.age.value = value
                        self?.tableView.reloadRows(at: [IndexPath(row: 2, section: Section.info.rawValue)], with: .none)
                    }
                    extracted.append(Patient.Keys.age)
                case .some(Patient.Keys.respiratoryRate):
                    DispatchQueue.main.async { [weak self] in
                        self?.observation.respiratoryRate.value = value
                        self?.tableView.reloadRows(at: [IndexPath(row: 0, section: Section.vitals.rawValue)], with: .none)
                    }
                    guess = nil
                    extracted.append(Patient.Keys.respiratoryRate)
                case .some(Patient.Keys.pulse):
                    DispatchQueue.main.async { [weak self] in
                        self?.observation.pulse.value = value
                        self?.tableView.reloadRows(at: [IndexPath(row: 1, section: Section.vitals.rawValue)], with: .none)
                    }
                    guess = nil
                    extracted.append(Patient.Keys.pulse)
                case .some(Patient.Keys.capillaryRefill):
                    DispatchQueue.main.async { [weak self] in
                        self?.observation.capillaryRefill.value = value
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
                        self?.observation.firstName = token
                        self?.tableView.reloadRows(at: [IndexPath(row: 0, section: Section.info.rawValue)], with: .none)
                    }
                    guess = Patient.Keys.lastName
                    extracted.append(Patient.Keys.firstName)
                } else if guess == Patient.Keys.lastName {
                    DispatchQueue.main.async { [weak self] in
                        self?.observation.lastName = token
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
        guard let audioHelper = audioHelper else { return }
        audioHelper.delegate = self
        do {
            try audioHelper.recordPressed()

            // hide and disable play button
            playButton.setImage(nil, for: .normal)
            playButton.isUserInteractionEnabled = false
            
            // disable tableview and modal presentation interaction so that recording does not get interrupted by accidental swipe movement
            tableView.isUserInteractionEnabled = false
            if let recognizers = navigationController?.presentationController?.presentedView?.gestureRecognizers {
                for recognizer in recognizers {
                    recognizer.isEnabled = false
                }
            }
        } catch {
            presentAlert(error: error)
        }
    }

    @IBAction func recordReleased(_ sender: Any) {
        guard let audioHelper = audioHelper else { return }
        audioHelper.recordReleased()

        // start upload
        dispatchGroup.enter()
        uploadTask = ApiClient.shared.upload(fileURL: audioHelper.fileURL) { [weak self] (response, error) in
            guard let self = self else { return }
            if let error = error {
                print(error)
            } else if let response = response, let signedId = response["signed_id"] as? String {
                self.observation.audioUrl = signedId
            }
            self.dispatchGroup.leave()
        }
        uploadTask?.resume()
        
        // show playback button
        playButton.setImage(UIImage(named: "Play"), for: .normal)
        playButton.sizeToFit()
        playButton.isUserInteractionEnabled = true

        // re-enable tableview and model presentation interaction
        tableView.isUserInteractionEnabled = true
        if let recognizers = navigationController?.presentationController?.presentedView?.gestureRecognizers {
            for recognizer in recognizers {
                recognizer.isEnabled = true
            }
        }
    }
    
    // MARK: - AudioHelperDelegate
    
    func audioHelper(_ audioHelper: AudioHelper, didRecognizeText text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.observation.text = text
            self?.tableView.reloadSections(IndexSet(integer: Section.observations.rawValue), with: .none)
        }
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.extractValues(text: text)
        }
    }

    func audioHelper(_ audioHelper: AudioHelper, didRecord seconds: TimeInterval, formattedDuration duration: String) {
        DispatchQueue.main.async { [weak self] in
            self?.playButton.setTitle(duration, for: .normal)
            self?.playButton.sizeToFit()
        }
    }

    func audioHelper(_ audioHelper: AudioHelper, didRequestSpeechAuthorization status: SFSpeechRecognizerAuthorizationStatus) {
        if status != .authorized {
            DispatchQueue.main.async { [weak self] in
                self?.presentAlert(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Speech Recognition is not authorized.", comment: ""))
            }
        }
    }

    // MARK: - AttributeTableViewCellDelegate

    func attributeTableViewCell(_ cell: AttributeTableViewCell, didChange text: String) {
        observation.setValue(text, forKey: cell.attribute)
    }
    
    // MARK: - LatLngTableViewCellDelegate
    
    func latLngTableViewCellDidClear(_ cell: LatLngTableViewCell) {
        observation.lat = ""
        observation.lng = ""
    }
    
    func latLngTableViewCell(_ cell: LatLngTableViewCell, didCapture lat: String, lng: String) {
        observation.lat = lat
        observation.lng = lng
    }

    // MARK: - PatientViewDelegate

    func patientView(_ patientView: PatientView, didCapturePhoto fileURL: URL, withImage image: UIImage) {
        dispatchGroup.enter()
        uploadTask = ApiClient.shared.upload(fileURL: fileURL) { [weak self] (response, error) in
            if let error = error {
                print(error)
            } else if let response = response, let signedId = response["signed_id"] as? String {
                self?.observation.portraitUrl = signedId
                AppCache.cache(fileURL: fileURL, pathPrefix: "uploads/observations/portrait", filename: signedId)
            }
            self?.dispatchGroup.leave()
        }
        uploadTask?.resume()
    }

    // MARK: - PriorityViewDelegate
    
    override func priorityView(_ view: PriorityView, didSelect priority: Int) {
        observation.priority.value = priority
        tableView.reloadSections(IndexSet(arrayLiteral: 0, 1), with: .none)
        view.removeFromSuperview()
    }

    // MARK: - TextViewTableViewCellDelegate

    func textViewTableViewCell(_ cell: TextViewTableViewCell, didChange text: String) {
        observation.text = text
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func textViewTableViewCellDidReturn(_ cell: TextViewTableViewCell) {
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
            if let text = observation.text {
                return TextViewTableViewCell.heightForText(text, width: tableView.frame.width)
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
                if let lat = observation.lat, let lng = observation.lng, lat != "", lng != "" {
                    if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Map") as? PatientMapViewController {
                        vc.patient = observation
                        navigationController?.pushViewController(vc, animated: true)
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
            cell.configure(from: observation)
            if let cell = cell as? PortraitTableViewCell {
                cell.patientView.cameraHelper = cameraHelper
                cell.patientView.delegate = self
            }
        }
        return cell
    }
}
