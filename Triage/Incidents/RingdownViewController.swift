//
//  RingdownViewController.swift
//  Triage
//
//  Created by Francis Li on 11/4/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import AgoraRtmKit
import ArkanaKeys
import UIKit
import PRKit
internal import RealmSwift
import RollbarNotifier

protocol RingdownViewControllerDelegate: AnyObject {
    func ringdownViewControllerDidSaveReport(_ vc: RingdownViewController)
}

// swiftlint:disable:next type_body_length
class RingdownViewController: BaseViewController, CheckboxDelegate, FormBuilder, KeyboardAwareScrollViewController,
                              RingdownFacilityViewDelegate, RingdownStatusViewDelegate, AgoraRtmClientDelegate, CallViewControllerDelegate {
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
    var formComponents: [String: PRKit.FormComponent] = [:]

    var report: Report!
    var ringdown: Ringdown?

    var results: Results<HospitalStatusUpdate>?
    var notificationToken: NotificationToken?

    var ringdownResults: Results<Ringdown>?
    var ringdownNotificationToken: NotificationToken?

    weak var delegate: RingdownViewControllerDelegate?

    var rtmKit: AgoraRtmClientKit!
    var callId: UUID?

    deinit {
        notificationToken?.invalidate()
        ringdownNotificationToken?.invalidate()

        rtmKit?.logout()
        rtmKit?.destroy()
        rtmKit = nil
    }

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .background
        mainView.addSubview(scrollView)
        let scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: mainView.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            scrollViewBottomConstraint
        ])
        self.scrollView = scrollView
        self.scrollViewBottomConstraint = scrollViewBottomConstraint

        let containerView = UIStackView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.axis = .vertical
        containerView.alignment = .fill
        containerView.distribution = .fill
        containerView.spacing = 0
        scrollView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            containerView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        self.containerView = containerView

        footerView.isHidden = true

        let commandFooter = CommandFooter()
        commandFooter.translatesAutoresizingMaskIntoConstraints = false
        commandFooter.preservesSuperviewLayoutMargins = true
        footerView.addSubview(commandFooter)
        NSLayoutConstraint.activate([
            commandFooter.topAnchor.constraint(equalTo: footerView.topAnchor),
            commandFooter.leftAnchor.constraint(equalTo: footerView.leftAnchor),
            commandFooter.rightAnchor.constraint(equalTo: footerView.rightAnchor),
            footerView.bottomAnchor.constraint(equalTo: commandFooter.bottomAnchor)
        ])
        self.commandFooter = commandFooter

        let actionButton = PRKit.Button()
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.style = .primary
        commandFooter.addSubview(actionButton)
        self.actionButton = actionButton

        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        self.activityIndicatorView = activityIndicatorView
        if report.ringdownId != nil {
            activityIndicatorView.startAnimating()
        }

        let checkboxesView = UIStackView()
        checkboxesView.translatesAutoresizingMaskIntoConstraints = false
        checkboxesView.alignment = .top
        checkboxesView.distribution = .fillEqually
        checkboxesView.spacing = 0
        containerView.addArrangedSubview(checkboxesView)
        self.checkboxesView = checkboxesView

        var checkboxView = UIView()
        checkboxView.translatesAutoresizingMaskIntoConstraints = false
        checkboxesView.addArrangedSubview(checkboxView)

        var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .h4SemiBold
        label.textColor = .base500
        label.text = "RingdownViewController.urgency".localized
        checkboxView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: checkboxView.topAnchor, constant: 16),
            label.leftAnchor.constraint(equalTo: checkboxView.leftAnchor),
            label.rightAnchor.constraint(lessThanOrEqualTo: checkboxView.rightAnchor)
        ])

        let code2Checkbox = Checkbox()
        code2Checkbox.translatesAutoresizingMaskIntoConstraints = false
        code2Checkbox.delegate = self
        code2Checkbox.isRadioButton = true
        code2Checkbox.labelText = "RingdownViewController.urgency.code2".localized
        checkboxView.addSubview(code2Checkbox)
        NSLayoutConstraint.activate([
            code2Checkbox.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            code2Checkbox.leftAnchor.constraint(equalTo: label.leftAnchor),
            code2Checkbox.rightAnchor.constraint(equalTo: checkboxView.rightAnchor, constant: -20)
        ])
        self.code2Checkbox = code2Checkbox

        let code3Checkbox = Checkbox()
        code3Checkbox.translatesAutoresizingMaskIntoConstraints = false
        code3Checkbox.delegate = self
        code3Checkbox.isRadioButton = true
        code3Checkbox.labelText = "RingdownViewController.urgency.code3".localized
        checkboxView.addSubview(code3Checkbox)
        NSLayoutConstraint.activate([
            code3Checkbox.topAnchor.constraint(equalTo: code2Checkbox.bottomAnchor, constant: 12),
            code3Checkbox.leftAnchor.constraint(equalTo: code2Checkbox.leftAnchor),
            code3Checkbox.rightAnchor.constraint(equalTo: code2Checkbox.rightAnchor),
            checkboxView.bottomAnchor.constraint(equalTo: code3Checkbox.bottomAnchor, constant: 12)
        ])
        self.code3Checkbox = code3Checkbox

        checkboxView = UIView()
        checkboxView.translatesAutoresizingMaskIntoConstraints = false
        checkboxesView.addArrangedSubview(checkboxView)

        let vr = PixelRuleView()
        vr.translatesAutoresizingMaskIntoConstraints = false
        vr.left = true
        vr.bottom = false
        vr.widthAnchor.constraint(equalToConstant: 1).isActive = true
        checkboxesView.addSubview(vr)
        NSLayoutConstraint.activate([
            vr.topAnchor.constraint(equalTo: checkboxView.topAnchor, constant: 16),
            vr.leftAnchor.constraint(equalTo: checkboxView.leftAnchor),
            vr.bottomAnchor.constraint(equalTo: checkboxView.bottomAnchor)
        ])

        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .h4SemiBold
        label.textColor = .base500
        label.text = "RingdownViewController.stability".localized
        checkboxView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: checkboxView.topAnchor, constant: 16),
            label.leftAnchor.constraint(equalTo: checkboxView.leftAnchor),
            label.rightAnchor.constraint(lessThanOrEqualTo: checkboxView.rightAnchor)
        ])

        let stableCheckbox = Checkbox()
        stableCheckbox.translatesAutoresizingMaskIntoConstraints = false
        stableCheckbox.delegate = self
        stableCheckbox.isRadioButton = true
        stableCheckbox.labelText = "RingdownViewController.stability.stable".localized
        checkboxView.addSubview(stableCheckbox)
        NSLayoutConstraint.activate([
            stableCheckbox.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            stableCheckbox.leftAnchor.constraint(equalTo: label.leftAnchor),
            stableCheckbox.rightAnchor.constraint(equalTo: checkboxView.rightAnchor, constant: -20)
        ])
        self.stableCheckbox = stableCheckbox

        let unstableCheckbox = Checkbox()
        unstableCheckbox.translatesAutoresizingMaskIntoConstraints = false
        unstableCheckbox.delegate = self
        unstableCheckbox.isRadioButton = true
        unstableCheckbox.labelText = "RingdownViewController.stability.unstable".localized
        checkboxView.addSubview(unstableCheckbox)
        NSLayoutConstraint.activate([
            unstableCheckbox.topAnchor.constraint(equalTo: stableCheckbox.bottomAnchor, constant: 12),
            unstableCheckbox.leftAnchor.constraint(equalTo: stableCheckbox.leftAnchor),
            unstableCheckbox.rightAnchor.constraint(equalTo: stableCheckbox.rightAnchor),
            checkboxView.bottomAnchor.constraint(equalTo: unstableCheckbox.bottomAnchor, constant: 12)
        ])
        self.unstableCheckbox = unstableCheckbox

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
            .sorted(by: [
                SortDescriptor(keyPath: "sortType", ascending: true),
                SortDescriptor(keyPath: "sortSequenceNumber", ascending: true)
            ])
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
            REDRealm.getRingdown(id: ringdownId) { [weak self] (_, error) in
                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        self?.presentAlert(error: error)
                    }
                }
            }
            let keys = ArkanaKeys.Global()
            rtmKit = try? AgoraRtmClientKit(AgoraRtmClientConfig(appId: keys.agoraAppId, userId: ringdownId), delegate: self)
            let task = PRApiClient.shared.getRtmToken(channelName: ringdownId) { [weak self] (_, _, data, error) in
                guard let self = self else { return }
                if let error = error {
                    Rollbar.errorError(error)
                    DispatchQueue.main.async { [weak self] in
                        self?.presentUnexpectedErrorAlert()
                    }
                } else if let data = data, let token = data["token"] as? String {
                    self.rtmKit.login(token) { (_, error) in
                        if let error = error {
                            Rollbar.errorError(error)
                            DispatchQueue.main.async { [weak self] in
                                self?.presentUnexpectedErrorAlert()
                            }
                        }
                    }
                }
            }
            task.resume()
        }
    }

    func addNewFacilityView(for update: HospitalStatusUpdate) {
        let facilityView = RingdownFacilityView()
        facilityView.tag = update.sortSequenceNumber ?? 0
        facilityView.inputAccessoryView = formInputAccessoryView
        facilityView.delegate = self
        facilityView.update(from: update)
        facilityView.selectButton.isEnabled = isEditing
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

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            for checkbox in codeCheckboxes {
                checkbox.isEnabled = true
            }
            for checkbox in stabilityCheckboxes {
                checkbox.isEnabled = true
            }
            for facilityView in facilityViews {
                facilityView.selectButton.isEnabled = true
            }
            ringdownStatusView.cancelButton.isEnabled = true
            ringdownStatusView.redirectButton.isEnabled = true
        } else {
            hideFooter()
            for checkbox in codeCheckboxes {
                checkbox.isEnabled = false
            }
            for checkbox in stabilityCheckboxes {
                checkbox.isEnabled = false
            }
            for facilityView in facilityViews {
                facilityView.selectButton.isEnabled = false
            }
            ringdownStatusView.cancelButton.isEnabled = false
            ringdownStatusView.redirectButton.isEnabled = false
        }
    }

    func showRingdown() {
        guard let ringdown = ringdown else { return }
        ringdownStatusView.update(from: ringdown)
        facilitiesSection.isHidden = true
        ringdownSection.isHidden = false
        if isEditing {
            showFooter()
        }
        activityIndicatorView.stopAnimating()
        let timestamps = ringdown.timestamps
        if timestamps[RingdownStatus.returnedToService.rawValue] != nil {
            hideFooter()
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
        hideFooter()
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
                let ringdownId = ringdown.id
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let realm = AppRealm.open()
                    if let report = realm.object(ofType: Report.self, forPrimaryKey: reportId) {
                        let newReport = Report(clone: report)
                        newReport.ringdownId = ringdownId
                        if let facilityId = facilityId {
                            newReport.disposition?.destinationFacility = realm.object(ofType: Facility.self, forPrimaryKey: facilityId)
                        }
                        AppRealm.saveReport(report: newReport)
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

    // MARK: - AgoraRtmClientDelegate

    func rtmKit(_ rtmClient: AgoraRtmClientKit, didReceiveMessageEvent event: AgoraRtmMessageEvent) {
        guard let ringdownId = ringdown?.id, let rawData = event.message.rawData ?? event.message.stringData?.data(using: .utf8), let data = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any] else {
            return
        }
        if callId == nil {
            let callId = UUID()
            CallHelper.shared.ring(id: callId, from: data["name"] as? String ?? "Unknown", answer: { [weak self] in
                let vc = CallViewController()
                vc.delegate = self
                vc.callReason = .ringdown
                vc.callId = callId
                vc.callName = data["name"] as? String ?? "Unknown"
                vc.callChannelName = data["userId"] as? String ?? ""
                DispatchQueue.main.async { [weak self] in
                    self?.presentAnimated(vc)
                }
                self?.callId = nil
            }, decline: { [weak self] in
                let publishOptions = AgoraRtmPublishOptions()
                publishOptions.channelType = .user
                var newData = data
                newData["status"] = "declined" as Any
                // swiftlint:disable:next force_try
                self?.rtmKit.publish(channelName: data["userId"] as? String ?? "", data: try! JSONSerialization.data(withJSONObject: newData), option: publishOptions)
                self?.callId = nil
            }) { [weak self] (error) in
                if let error = error {
                    Rollbar.errorError(error)
                    DispatchQueue.main.async { [weak self] in
                        self?.presentUnexpectedErrorAlert()
                    }
                }
                self?.callId = nil
            }
            self.callId = callId
        } else {
            // TODO: return a "busy" message
        }
    }

    // MARK: - CallViewControllerDelegate

    func callViewControllerDidFinish(_ vc: CallViewController) {
        vc.dismiss(animated: true)
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
            showFooter()
            validateRingdown()
        } else {
            hideFooter()
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
