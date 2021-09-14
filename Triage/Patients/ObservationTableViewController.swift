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

class ObservationTableViewController: PatientTableViewController, LocationHelperDelegate, PortraitViewDelegate,
                                      RecordingViewControllerDelegate {
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    weak var scrollIndicatorView: ScrollIndicatorView!

    let dispatchGroup = DispatchGroup()
    var uploadTask: URLSessionTask?

    var locationHelper: LocationHelper!
    var cameraHelper: CameraHelper!
    var originalPatient: Patient!
    var startingOffsetY: CGFloat = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        let scrollIndicatorView = ScrollIndicatorView()
        scrollIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollIndicatorView)
        NSLayoutConstraint.activate([
            scrollIndicatorView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollIndicatorView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollIndicatorView.bottomAnchor.constraint(equalTo: updateButtonBackgroundView.topAnchor, constant: 11)
        ])
        self.scrollIndicatorView = scrollIndicatorView

        locationHelper = LocationHelper()
        locationHelper.delegate = self

        cameraHelper = CameraHelper()

        // make a copy of the observation object before editing for comparison
        originalPatient = Patient(clone: patient!)

        if let tableHeaderView = tableView.tableHeaderView as? PatientHeaderView {
            tableHeaderView.portraitView.isEditing = true
            tableHeaderView.portraitView.cameraHelper = cameraHelper
            tableHeaderView.portraitView.delegate = self
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
        // change editing state after layout prevents layout constraint warnings
        setEditing(true, animated: false)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        if startingOffsetY >= 0 {
            tableView.setContentOffset(CGPoint(x: 0, y: startingOffsetY), animated: false)
            startingOffsetY = -1
        }
    }

    override func cancelTransport() {
        patient.setTransported(false)
        tableView.reloadSections(IndexSet([Section.priority.rawValue, Section.location.rawValue]), with: .none)
        if let tableViewHeader = tableView.tableHeaderView as? PatientHeaderView {
            tableViewHeader.configure(from: patient)
        }
        if let priority = patient.filterPriority.value {
            delegate?.patientTableViewController?(self, didUpdatePriority: priority)
        }
    }

    @IBAction func cancelPressed() {
        delegate?.patientTableViewControllerDidCancel?(self)
    }

    @IBAction func savePressed(_ sender: Any) {
        if patient.priority.value == nil {
            presentAlert(title: "Error".localized, message: "Please select a SALT priority")
            return
        }

        AppRealm.createOrUpdatePatient(patient: patient.changes(from: self.originalPatient))

        delegate?.patientTableViewControllerDidSave?(self)
    }

    private func captureLocation() {
        locationHelper.requestLocation()
        if let cell = tableView.cellForRow(at: IndexPath(row: 3, section: Section.info.rawValue)) as? LocationTableViewCell {
            cell.setCapturing(true)
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

    func attributeTableViewCell(_ cell: AttributeTableViewCell, didChange text: String,
                                for attribute: String, with type: String) {
        let attributeType = AttributeTableViewCellType(rawValue: type)
        if attributeType == .object {
            if text.isEmpty {
                patient.setValue(nil, forKey: attribute)
                patient.setPredictionStatus(.corrected, for: attribute)
            }
        } else {
            patient.setValue(text, forKey: attribute)
            patient.setPredictionStatus(.corrected, for: attribute)
            if attribute == Patient.Keys.location, text.isEmpty {
                patient.clearLatLng()
                cell.configure(from: patient)
            }
        }
        if attribute == Patient.Keys.transportAgency || attribute == Patient.Keys.transportFacility {
            tableView.reloadSections(IndexSet([Section.info.rawValue]), with: .none)
        }
    }

    func attributeTableViewCellDidConfirmStatus(_ cell: AttributeTableViewCell, for attribute: String, with type: String) {
        patient.setPredictionStatus(.confirmed, for: attribute)
    }

    override func attributeTableViewCellDidPressAlert(_ cell: AttributeTableViewCell, for attribute: String, with type: String) {
        if cell as? LocationTableViewCell != nil {
            if !patient.hasLatLng {
                captureLocation()
                return
            }
        }
        super.attributeTableViewCellDidPressAlert(cell, for: attribute, with: type)
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
        patient.setTransported(true)
        patient.transportFacility = facility
        patient.transportAgency = agency
        tableView.reloadSections(IndexSet([Section.priority.rawValue, Section.location.rawValue]), with: .none)
        if let tableViewHeader = tableView.tableHeaderView as? PatientHeaderView {
            tableViewHeader.configure(from: patient)
        }
        delegate?.patientTableViewController?(self, didUpdatePriority: Priority.transported.rawValue)
    }

    // MARK: - FacilitiesTableViewControllerDelegate

    override func facilitiesTableViewControllerDidConfirmLeavingIndependently(_ vc: FacilitiesTableViewController) {
        patient.setTransported(true, isTransportedLeftIndependently: true)
        tableView.reloadSections(IndexSet([Section.priority.rawValue, Section.location.rawValue]), with: .none)
        if let tableViewHeader = tableView.tableHeaderView as? PatientHeaderView {
            tableViewHeader.configure(from: patient)
        }
        delegate?.patientTableViewController?(self, didUpdatePriority: Priority.transported.rawValue)
    }

    // MARK: - LocationHelperDelegate

    func locationHelper(_ helper: LocationHelper, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            patient.lat = String(format: "%.6f", location.coordinate.latitude)
            patient.lng = String(format: "%.6f", location.coordinate.longitude)
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 3, section: Section.info.rawValue)) as? LocationTableViewCell {
            cell.configure(from: patient)
            cell.setCapturing(false)
        }
    }

    func locationHelper(_ helper: LocationHelper, didFailWithError error: Error) {
        if let cell = tableView.cellForRow(at: IndexPath(row: 3, section: Section.info.rawValue)) as? LocationTableViewCell {
            cell.setCapturing(false)
        }
        presentAlert(error: error)
    }

    // MARK: - PatientViewDelegate

    func patientView(_ patientView: PortraitView, didCapturePhoto fileURL: URL, withImage image: UIImage) {
        AppRealm.uploadPatientAsset(patient: patient, key: Patient.Keys.portraitFile, fileURL: fileURL)
    }

    // MARK: - PriorityTableViewCellDelegate

    override func priorityTableViewCell(_ cell: PriorityTableViewCell, didSelect priority: Int) {
        if let priority = Priority(rawValue: priority) {
            patient.setPriority(priority)
            delegate?.patientTableViewController?(self, didUpdatePriority: priority.rawValue)
            tableView.reloadSections(IndexSet(integer: Section.priority.rawValue), with: .none)
        }
    }

    // MARK: - RecordingViewControllerDelegate

    func recordingViewController(_ vc: RecordingViewController, didRecognizeText text: String,
                                 sourceId: String, metadata: [String: Any], isFinal: Bool) {
        patient.text = text
        tableView.reloadSections(IndexSet(integer: Section.observations.rawValue), with: .none)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.patient.extractValues(from: text, sourceId: sourceId, metadata: metadata, isFinal: isFinal)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
                if let priority = self.patient.filterPriority.value {
                    self.delegate?.patientTableViewController?(self, didUpdatePriority: priority)
                }
            }
        }
    }

    func recordingViewController(_ vc: RecordingViewController, didFinishRecording fileURL: URL) {
        AppRealm.uploadPatientAsset(patient: patient, key: Patient.Keys.audioFile, fileURL: fileURL)
        tableView.reloadSections(IndexSet(integer: Section.observations.rawValue), with: .none)
        // hide the record button, user must clear current recording to continue
        updateButton.isHidden = true
        updateButtonBackgroundView.isHidden = true
        scrollIndicatorView.isHidden = true
    }

    func recordingViewController(_ vc: RecordingViewController, didThrowError error: Error) {
        switch error {
        case AudioHelperError.speechRecognitionNotAuthorized:
            // even with speech recognition off, we can still allow a recording...
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

    // MARK: - UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.5) {
            self.scrollIndicatorView.alpha = 0
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y == 0 {
            UIView.animate(withDuration: 0.25) {
                self.scrollIndicatorView.alpha = 1
            }
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
