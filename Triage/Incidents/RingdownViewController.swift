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

class RingdownViewController: UIViewController, CheckboxDelegate, FormViewController, KeyboardAwareScrollViewController,
                              RingdownFacilityViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIStackView!
    @IBOutlet weak var actionButtonBackground: UIView!
    @IBOutlet weak var actionButton: PRKit.Button!

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
    weak var ringdownStatusView: RingdownStatusView!
    weak var ringdownSection: FormSection!

    var formInputAccessoryView: UIView!
    var formFields: [PRKit.FormField] = []

    var report: Report!
    var ringdown: Ringdown?

    var results: Results<HospitalStatusUpdate>?
    var notificationToken: NotificationToken?

    var ringdownResults: Results<Ringdown>?
    var ringdownNotificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
        ringdownNotificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        actionButtonBackground.addShadow(withOffset: CGSize(width: 4, height: -4), radius: 20, color: .base500, opacity: 0.2)

        codeCheckboxes = [code2Checkbox, code3Checkbox]
        code3Checkbox.isEnabled = false
        stabilityCheckboxes = [stableCheckbox, unstableCheckbox]

        var (section, cols, colA, colB) = newSection()
        colA.spacing = 0
        colB.spacing = 0
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
        colA.addArrangedSubview(ringdownStatusView)
        self.ringdownStatusView = ringdownStatusView
        containerView.addArrangedSubview(section)
        self.ringdownSection = section

        formInputAccessoryView = FormInputAccessoryView(rootView: containerView)

        let realm = VLRealm.open()
        results = realm.objects(HospitalStatusUpdate.self)
            .sorted(by: [SortDescriptor(keyPath: "sortSequenceNumber", ascending: true)])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }

        if let ringdownId = report.ringdownId {
            ringdownResults = realm.objects(Ringdown.self).filter("id=%@", ringdownId)
            ringdownNotificationToken = ringdownResults?.observe { [weak self] (changes) in
                self?.didObserveRingdownRealmChanges(changes)
            }
        }
    }

    func addNewFacilityView(for update: HospitalStatusUpdate) {
        let facilityView = RingdownFacilityView()
        facilityView.tag = update.sortSequenceNumber ?? 0
        facilityView.inputAccessoryView = formInputAccessoryView
        facilityView.delegate = self
        facilityView.update(from: update)
        let col = ((update.sortSequenceNumber ?? 1) - 1).isMultiple(of: 2) ? facilitiesSection.colA : facilitiesSection.colB
        col?.addArrangedSubview(facilityView)
        let hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        col?.addArrangedSubview(hr)
    }

    func showRingdown() {
        guard let ringdown = ringdown else { return }
        ringdownStatusView.update(from: ringdown)
        facilitiesSection.isHidden = true
        ringdownSection.isHidden = false
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
            var facilityViews: [RingdownFacilityView] = []
            FormSection.subviews(&facilityViews, in: facilitiesSection)
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

    func validateRingdown() {
        actionButton.isEnabled = false
        var facilityViews: [RingdownFacilityView] = []
        FormSection.subviews(&facilityViews, in: facilitiesSection)
        guard let facilityView = facilityViews.first(where: { $0.isSelected }) else { return }
        guard Int(facilityView.arrivalText ?? "") != nil else { return }
        actionButton.isEnabled = emergencyServiceResponseType != nil && stableIndicator != nil
    }

    @IBAction func actionPressed() {
        if let ringdown = ringdown {

        } else {
            var payload = report.asRingdownJSON()
            var facilityViews: [RingdownFacilityView] = []
            FormSection.subviews(&facilityViews, in: facilitiesSection)
            guard let index = facilityViews.firstIndex(where: { $0.isSelected }) else { return }
            if let update = results?[index] {
                payload["hospital"] = [
                    "id": update.id
                ]
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
            VLRealm.sendRingdown(payload: payload) { [weak self] (ringdown, error) in
                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        self?.presentAlert(error: error)
                    }
                } else if let ringdown = ringdown {
                    let ringdownId = ringdown.id
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.ringdown = VLRealm.open().object(ofType: Ringdown.self, forPrimaryKey: ringdownId)
                        self.showRingdown()
                        let newReport = Report(clone: self.report)
                        newReport.ringdownId = ringdownId
                        AppRealm.saveReport(report: newReport)
                    }
                }
            }
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
            var facilityViews: [RingdownFacilityView] = []
            FormSection.subviews(&facilityViews, in: facilitiesSection)
            for facilityView in facilityViews {
                facilityView.isSelected = facilityView == view
            }
            scrollView.scrollRectToVisible(view.convert(view.bounds, to: scrollView), animated: true)
        }
    }

    func ringdownFacilityView(_ view: RingdownFacilityView, didChangeEta eta: String?) {
        if let eta = eta, Int(eta) != nil {
            actionButton.setTitle("Button.sendRingdown".localized, for: .normal)
            actionButton.isHidden = false
            actionButtonBackground.isHidden = false
            validateRingdown()
        } else {
            actionButton.isHidden = true
            actionButtonBackground.isHidden = true
        }
    }
}
