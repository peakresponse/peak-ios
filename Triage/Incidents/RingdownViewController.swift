//
//  RingdownViewController.swift
//  Triage
//
//  Created by Francis Li on 11/4/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import PRKit
import RealmSwift

protocol RingdownViewControllerDelegate: AnyObject {
    func ringdownViewControllerDidSaveReport(_ vc: RingdownViewController)
}

class RingdownViewController: UIViewController, CheckboxDelegate, FormBuilder, KeyboardAwareScrollViewController,
                              RingdownFacilityViewDelegate, RingdownStatusViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIStackView!
    @IBOutlet weak var commandFooter: CommandFooter!
    @IBOutlet weak var actionButton: PRKit.Button!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet weak var checkboxesView: UIStackView!
    @IBOutlet weak var code2Checkbox: Checkbox!
    @IBOutlet weak var code3Checkbox: Checkbox!
    var codeCheckboxes: [Checkbox]!
    var emergencyServiceResponseType: RingdownEmergencyServiceResponseType? {
        if code2Checkbox.isChecked {
            return .code2
        } else if code3Checkbox.isChecked {
            return .code3
        }
        return nil
    }
    @IBOutlet weak var stableCheckbox: Checkbox!
    @IBOutlet weak var unstableCheckbox: Checkbox!
    var stabilityCheckboxes: [Checkbox]!
    var stableIndicator: Bool? {
        if stableCheckbox.isChecked {
            return true
        } else if unstableCheckbox.isChecked {
            return false
        }
        return nil
    }

    weak var facilitiesSection: FormSection!
    var facilityViews: [RingdownFacilityView] = []

    weak var ringdownStatusView: RingdownStatusView!
    weak var ringdownSection: FormSection!

    var formInputAccessoryView: UIView!
    var formFields: [String: PRKit.FormField] = [:]

    var report: Report!
    var ringdown: Ringdown?

    var results: Results<HospitalStatusUpdate>?
    var notificationToken: NotificationToken?

    var ringdownResults: Results<Ringdown>?
    var ringdownNotificationToken: NotificationToken?

    weak var delegate: RingdownViewControllerDelegate?

    deinit {
        notificationToken?.invalidate()
        ringdownNotificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if report.ringdownId == nil {
            activityIndicatorView.stopAnimating()
        }

        codeCheckboxes = [code2Checkbox, code3Checkbox]
        stabilityCheckboxes = [stableCheckbox, unstableCheckbox]

        var (section, cols, colA, colB) = newSection()
        colA.spacing = 0
        colB.spacing = 0
        section.isHidden = report.ringdownId != nil
        section.addArrangedSubview(checkboxesView)

        let hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        section.addArrangedSubview(hr)

        section.addArrangedSubview(cols)
        containerView.addArrangedSubview(section)
        self.facilitiesSection = section

        (section, cols, colA, colB) = newSection()
        section.isHidden = true
        section.addArrangedSubview(cols)
        let ringdownStatusView = RingdownStatusView()
        ringdownStatusView.delegate = self
        colA.addArrangedSubview(ringdownStatusView)
        self.ringdownStatusView = ringdownStatusView
        containerView.addArrangedSubview(section)
        self.ringdownSection = section

        formInputAccessoryView = FormInputAccessoryView(rootView: containerView)

        let realm = REDRealm.open()
        results = realm.objects(HospitalStatusUpdate.self)
            .sorted(by: [SortDescriptor(keyPath: "sortSequenceNumber", ascending: true)])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }

        performRingdownQuery()
    }

    func performRingdownQuery() {
        if let ringdownId = report.ringdownId {
            let realm = REDRealm.open()
            ringdownResults = realm.objects(Ringdown.self).filter("id=%@", ringdownId)
            ringdownNotificationToken = ringdownResults?.observe { [weak self] (changes) in
                self?.didObserveRingdownRealmChanges(changes)
            }
            if ringdownResults?.count == 0 {
                REDRealm.getRingdown(id: ringdownId) { [weak self] (_, error) in
                    if let error = error {
                        DispatchQueue.main.async { [weak self] in
                            self?.presentAlert(error: error)
                        }
                    }
                }
            }
        }
    }

    func addNewFacilityView(for update: HospitalStatusUpdate) {
        let facilityView = RingdownFacilityView()
        facilityView.tag = update.sortSequenceNumber ?? 0
        facilityView.inputAccessoryView = formInputAccessoryView
        facilityView.delegate = self
        facilityView.update(from: update)
        facilityViews.append(facilityView)

        let col = ((update.sortSequenceNumber ?? 1) - 1).isMultiple(of: 2) ? facilitiesSection.colA : facilitiesSection.colB
        col?.addArrangedSubview(facilityView)

        let hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        col?.addArrangedSubview(hr)
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<HospitalStatusUpdate>>) {
        switch changes {
        case .initial:
            if let results = results {
                for update in results {
                    addNewFacilityView(for: update)
                }
            }
        case .update(let results, _, let insertions, let modifications):
            for index in insertions {
                let update = results[index]
                addNewFacilityView(for: update)
            }
            for index in modifications {
                let update = results[index]
                facilityViews[index].update(from: update)
            }
        case .error(let error):
            presentAlert(error: error)
        }
    }

    func didObserveRingdownRealmChanges(_ changes: RealmCollectionChange<Results<Ringdown>>) {
        switch changes {
        case .initial:
            if let results = ringdownResults, results.count > 0 {
                ringdown = results[0]
                showRingdown()
            }
        case .update(let results, _, _, _):
            if ringdown == nil, results.count > 0 {
                ringdown = results[0]
            }
            showRingdown()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
    }

    func showCommandFooter() {
        commandFooter.isHidden = false
        let inset = UIEdgeInsets(top: 0, left: 0, bottom: commandFooter.frame.height, right: 0)
        scrollView.contentInset = inset
        scrollView.scrollIndicatorInsets = inset
    }

    func hideCommandFooter() {
        commandFooter.isHidden = true
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    func showRingdown() {
        guard let ringdown = ringdown else { return }
        ringdownStatusView.update(from: ringdown)
        facilitiesSection.isHidden = true
        ringdownSection.isHidden = false
        showCommandFooter()
        activityIndicatorView.stopAnimating()
        let timestamps = ringdown.timestamps
        if timestamps[RingdownStatus.returnedToService.rawValue] != nil {
            hideCommandFooter()
        } else if timestamps[RingdownStatus.offloaded.rawValue] != nil {
            actionButton.setTitle("Button.returnToService".localized, for: .normal)
        } else if timestamps[RingdownStatus.arrived.rawValue] != nil {
            actionButton.setTitle("Button.markOffloaded".localized, for: .normal)
        } else if timestamps[RingdownStatus.returnedToService.rawValue] == nil {
            actionButton.setTitle("Button.markArrived".localized, for: .normal)
        }
    }

    func hideRingdown() {
        ringdownSection.isHidden = true
        for facilityView in facilityViews {
            facilityView.isSelected = false
        }
        facilitiesSection.isHidden = false
        hideCommandFooter()
    }

    func validateRingdown() {
        actionButton.isEnabled = false
        guard let facilityView = facilityViews.first(where: { $0.isSelected }) else { return }
        guard Int(facilityView.arrivalText ?? "") != nil else { return }
        actionButton.isEnabled = emergencyServiceResponseType != nil && stableIndicator != nil
    }

    func sendRingdown() {
        var payload = report.asRingdownJSON()
        guard let index = facilityViews.firstIndex(where: { $0.isSelected }) else { return }
        var facilityId: String?
        if let update = results?[index] {
            payload["hospital"] = [
                "id": update.id
            ]
            if let stateId = update.state, let locationCode = update.stateFacilityCode {
                facilityId = AppRealm.open().objects(Facility.self).filter("stateId=%@ AND locationCode=%@", stateId, locationCode).first?.id
            }
        }
        let facilityView = facilityViews[index]
        if let eta = facilityView.arrivalText, let etaMinutes = Int(eta) {
            payload["patientDelivery"] = [
                "etaMinutes": etaMinutes
            ]
        }
        if var patient = payload["patient"] as? [String: Any] {
            if let stableIndicator = stableIndicator {
                patient["stableIndicator"] = stableIndicator
            }
            if let emergencyServiceResponseType = emergencyServiceResponseType {
                patient["emergencyServiceResponseType"] = emergencyServiceResponseType.rawValue
            }
            payload["patient"] = patient
        }
        commandFooter.isLoading = true
        let reportId = report.id
        REDRealm.sendRingdown(payload: payload) { [weak self] (ringdown, error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.commandFooter.isLoading = false
                    self?.presentAlert(error: error)
                }
            } else if let ringdown = ringdown {
                let realm = AppRealm.open()
                if let report = realm.object(ofType: Report.self, forPrimaryKey: reportId) {
                    let newReport = Report(clone: report)
                    newReport.ringdownId = ringdown.id
                    if let facilityId = facilityId {
                        newReport.disposition?.destinationFacility = realm.object(ofType: Facility.self, forPrimaryKey: facilityId)
                    }
                    AppRealm.saveReport(report: newReport)
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.ringdownViewControllerDidSaveReport(self)
                        self.performRingdownQuery()
                        self.commandFooter.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.commandFooter.isLoading = false
                    self?.presentAlert(error: ApiClientError.unexpected)
                }
            }
        }
    }

    func redirectRingdown() {
        cancelRingdown(status: .redirected)
    }

    func cancelRingdown(status: RingdownStatus = .cancelled) {
        guard let ringdown = ringdown else { return }
        commandFooter.isLoading = true
        let reportId = report.id
        REDRealm.setRingdownStatus(ringdown: ringdown, status: status) { [weak self] (error) in
            if error == nil {
                let realm = AppRealm.open()
                if let report = realm.object(ofType: Report.self, forPrimaryKey: reportId) {
                    let newReport = Report(clone: report)
                    newReport.ringdownId = nil
                    newReport.disposition?.destinationFacility = nil
                    AppRealm.saveReport(report: newReport)
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.ringdownViewControllerDidSaveReport(self)
                    }
                }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.commandFooter.isLoading = false
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    self.ringdownNotificationToken?.invalidate()
                    self.ringdownResults = nil
                    self.ringdown = nil
                    self.hideRingdown()
                }
            }
        }
    }

    @IBAction func actionPressed() {
        if let ringdown = ringdown {
            let timestamps = ringdown.timestamps
            commandFooter.isLoading = true
            let completionHandler = { [weak self] (error: Error?) in
                DispatchQueue.main.async { [weak self] in
                    self?.commandFooter.isLoading = false
                    if let error = error {
                        self?.presentAlert(error: error)
                    }
                }
            }
            if timestamps[RingdownStatus.offloaded.rawValue] != nil {
                REDRealm.setRingdownStatus(ringdown: ringdown, status: .returnedToService, completionHandler: completionHandler)
            } else if timestamps[RingdownStatus.arrived.rawValue] != nil {
                REDRealm.setRingdownStatus(ringdown: ringdown, status: .offloaded, completionHandler: completionHandler)
            } else if timestamps[RingdownStatus.returnedToService.rawValue] == nil {
                REDRealm.setRingdownStatus(ringdown: ringdown, status: .arrived, completionHandler: completionHandler)
            }
        } else {
            sendRingdown()
        }
    }

    // MARK: - CheckboxDelegate

    func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        if codeCheckboxes.contains(checkbox) {
            for codeCheckbox in codeCheckboxes {
                if codeCheckbox != checkbox {
                    codeCheckbox.isChecked = false
                }
            }
        } else if stabilityCheckboxes.contains(checkbox) {
            for stabilityCheckbox in stabilityCheckboxes {
                if stabilityCheckbox != checkbox {
                    stabilityCheckbox.isChecked = false
                }
            }
        }
        validateRingdown()
    }

    // MARK: - RingdownFacilityViewDelegate

    func ringdownFacilityView(_ view: RingdownFacilityView, didSelect isSelected: Bool) {
        if isSelected {
            for facilityView in facilityViews {
                facilityView.isSelected = facilityView == view
            }
            scrollView.scrollRectToVisible(view.convert(view.bounds, to: scrollView), animated: true)
        }
    }

    func ringdownFacilityView(_ view: RingdownFacilityView, didChangeEta eta: String?) {
        if let eta = eta, Int(eta) != nil {
            actionButton.setTitle("Button.sendRingdown".localized, for: .normal)
            showCommandFooter()
            validateRingdown()
        } else {
            hideCommandFooter()
        }
    }

    // MARK: - RingdownStatusViewDelegate

    func ringdownStatusViewDidPressCancel(_ view: RingdownStatusView) {
        let alert = UIAlertController(title: "RingdownViewController.alert.cancel.title".localized,
                                      message: "RingdownViewController.alert.cancel.message".localized,
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Button.confirmCancelTransport".localized, style: .destructive, handler: { [weak self] (_) in
            self?.cancelRingdown()
        }))
        alert.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel, handler: nil))
        presentAnimated(alert)
    }

    func ringdownStatusViewDidPressRedirect(_ view: RingdownStatusView) {
        let alert = UIAlertController(title: "RingdownViewController.alert.redirect.title".localized,
                                      message: "RingdownViewController.alert.redirect.message".localized,
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Button.confirmRedirectPatient".localized, style: .destructive, handler: { [weak self] (_) in
            self?.redirectRingdown()
        }))
        alert.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel, handler: nil))
        presentAnimated(alert)
    }
}
