//
//  ReportViewController.swift
//  Triage
//
//  Created by Francis Li on 11/4/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Keyboardy
import PRKit
import RealmSwift
import TranscriptionKit
import UIKit

protocol ReportViewControllerDelegate: AnyObject {
    func reportViewControllerNeedsEditing(_ vc: ReportViewController)
}

class ReportViewController: UIViewController, FormViewController, KeyboardAwareScrollViewController, RecordingViewControllerDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIStackView!
    @IBOutlet weak var recordButton: RecordButton!
    @IBOutlet weak var recordButtonBackground: UIView!
    var formInputAccessoryView: UIView!
    var formFields: [PRKit.FormField] = []

    var report: Report!
    var newReport: Report?

    weak var delegate: ReportViewControllerDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        recordButtonBackground.addShadow(withOffset: CGSize(width: 4, height: -4), radius: 20, color: .base500, opacity: 0.2)

        let scene = report.scene ?? Scene.newRecord()
        let time = report.time ?? Time.newRecord()
        let response = report.response ?? Response.newRecord()
        let narrative = report.narrative ?? Narrative.newRecord()
        let disposition = report.disposition ?? Disposition.newRecord()
        let patient = report.patient ?? Patient.newRecord()
        let situation = report.situation ?? Situation.newRecord()
        let history = report.history ?? History.newRecord()
        let vitals = Array(report.vitals)
        let procedures = Array(report.procedures)
        let medications = Array(report.medications)

        if traitCollection.horizontalSizeClass == .regular {
            NSLayoutConstraint.activate([
                containerView.widthAnchor.constraint(equalToConstant: 690)
            ])
        } else {
            NSLayoutConstraint.activate([
                containerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
                containerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20)
            ])
        }

        var (section, cols, colA, colB) = newSection()
        var tag = 1
        formInputAccessoryView = FormInputAccessoryView(rootView: view)
        addTextField(source: response, attributeKey: "incidentNumber",
                     keyboardType: .numbersAndPunctuation, tag: &tag, to: colA)
        addTextField(source: scene, attributeKey: "address", tag: &tag, to: colA)
        addTextField(source: response, attributeKey: "unitNumber", keyboardType: .numbersAndPunctuation, tag: &tag, to: colB)
        addTextField(source: time, attributeKey: "unitNotifiedByDispatch", attributeType: .datetime, tag: &tag, to: colB)
        addTextField(source: time, attributeKey: "arrivedAtPatient", attributeType: .datetime, tag: &tag, to: colB)
        addTextField(source: narrative, attributeKey: "text", tag: &tag, to: colA)
        addTextField(source: disposition,
                     attributeKey: "unitDisposition",
                     attributeType: .single(EnumKeyboardSource<UnitDisposition>()),
                     tag: &tag, to: colB)
        section.addArrangedSubview(cols)
        containerView.addArrangedSubview(section)

        (section, cols, colA, colB) = newSection()
        var header = newHeader("ReportViewController.patientInformation".localized,
                               subheaderText: "ReportViewController.optional".localized)
        section.addArrangedSubview(header)
        addTextField(source: patient, attributeKey: "firstName", tag: &tag, to: colA)
        addTextField(source: patient, attributeKey: "lastName", tag: &tag, to: colB)
        addTextField(source: patient, attributeKey: "dob", attributeType: .date, tag: &tag, to: colA)
        let innerCols = newColumns()
        addTextField(source: patient,
                     attributeKey: "ageArray",
                     attributeType: .integerWithUnit(EnumKeyboardSource<PatientAgeUnits>()),
                     tag: &tag, to: innerCols, withWrapper: true)
        addTextField(source: patient,
                     attributeKey: "gender",
                     attributeType: .single(EnumKeyboardSource<PatientGender>()),
                     tag: &tag, to: innerCols, withWrapper: true)
        colB.addArrangedSubview(innerCols)
        section.addArrangedSubview(cols)
        containerView.addArrangedSubview(section)

        (section, cols, colA, colB) = newSection()
        header = newHeader("ReportViewController.medicalInformation".localized,
                           subheaderText: "ReportViewController.optional".localized)
        section.addArrangedSubview(header)
        addTextField(source: situation, attributeKey: "chiefComplaint", tag: &tag, to: colA)
        addTextField(source: situation,
                     attributeKey: "primarySymptom",
                     attributeType: .custom(NemsisComboKeyboard(
                        field: "eSituation.09",
                        sources: [ICD10CMKeyboardSource()],
                        isMultiSelect: false,
                        negatives: [.notApplicable])),
                     tag: &tag, to: colB)
        addTextField(source: situation,
                     attributeKey: "otherAssociatedSymptoms",
                     attributeType: .custom(NemsisComboKeyboard(
                        field: "eSituation.10",
                        sources: [ICD10CMKeyboardSource()],
                        isMultiSelect: true,
                        negatives: [.notApplicable])),
                     tag: &tag, to: colB)
        addTextField(source: history,
                     attributeKey: "medicalSurgicalHistory",
                     attributeType: .custom(NemsisComboKeyboard(
                        field: "eHistory.08",
                        sources: [ICD10CMKeyboardSource()],
                        isMultiSelect: true,
                        negatives: [.notApplicable, .noneReported, .refused, .unabletoComplete, .unresponsive])),
                     tag: &tag, to: colA)
        addTextField(source: history,
                     attributeKey: "medicationAllergies",
                     attributeType: .custom(NemsisComboKeyboard(
                        field: "eHistory.06",
                        sources: [RxNormKeyboardSource(includeSystem: true)],
                        isMultiSelect: true,
                        negatives: [.notApplicable, .noKnownDrugAllergy, .refused, .unresponsive, .unabletoComplete],
                        includeSystem: true)),
                     tag: &tag, to: colA)
        addTextField(source: history,
                     attributeKey: "environmentalFoodAllergies",
                     attributeType: .custom(NemsisKeyboard(
                        field: "eHistory.07",
                        sources: [SNOMEDKeyboardSource()],
                        isMultiSelect: true)),
                     tag: &tag, to: colB)
        section.addArrangedSubview(cols)
        containerView.addArrangedSubview(section)

        if vitals.count == 0 {
            (section, cols, colA, colB) = newVitalsSection(0, source: Vital.newRecord(), tag: &tag)
            containerView.addArrangedSubview(section)
        } else {
            for (i, vital) in vitals.enumerated() {
                (section, cols, colA, colB) = newVitalsSection(i, source: vital, tag: &tag)
                containerView.addArrangedSubview(section)
            }
        }
        var button = newButton(bundleImage: "Plus24px", title: "Button.newVitals".localized)
        button.addTarget(self, action: #selector(newVitalsPressed(_:)), for: .touchUpInside)
        button.tag = tag
        section.addLastButton(button)

        tag += 10000
        if procedures.count == 0 {
            (section, cols, colA, colB) = newProceduresSection(0, source: Procedure.newRecord(), tag: &tag)
            containerView.addArrangedSubview(section)
        } else {
            for (i, procedure) in procedures.enumerated() {
                (section, cols, colA, colB) = newProceduresSection(i, source: procedure, tag: &tag)
                containerView.addArrangedSubview(section)
            }
        }
        button = newButton(bundleImage: "Plus24px", title: "Button.addProcedure".localized)
        button.addTarget(self, action: #selector(addProcedurePressed), for: .touchUpInside)
        button.tag = tag
        section.addLastButton(button)

        tag += 10000
        if medications.count == 0 {
            (section, cols, colA, colB) = newMedicationsSection(0, source: Medication.newRecord(), tag: &tag)
            containerView.addArrangedSubview(section)
        } else {
            for (i, medication) in medications.enumerated() {
                (section, cols, colA, colB) = newMedicationsSection(i, source: medication, tag: &tag)
                containerView.addArrangedSubview(section)
            }
        }
        button = newButton(bundleImage: "Plus24px", title: "Button.addMedication".localized)
        button.addTarget(self, action: #selector(addMedicationPressed), for: .touchUpInside)
        button.tag = tag
        section.addLastButton(button)

        setEditing(isEditing, animated: false)
    }

    func newVitalsSection(_ i: Int, source: Vital? = nil, target: Vital? = nil,
                          tag: inout Int) -> (FormSection, UIStackView, UIStackView, UIStackView) {
        let (section, cols, colA, colB) = newSection()
        section.source = source
        section.sourceIndex = i
        section.target = target

        let header = newHeader("ReportViewController.vitals".localized,
                               subheaderText: "ReportViewController.optional".localized)
        section.addArrangedSubview(header)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "vitalSignsTakenAt", attributeType: .datetime, tag: &tag, to: colA)
        let innerCols = newColumns()
        innerCols.distribution = .fillProportionally
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "bpSystolic", attributeType: .integer, tag: &tag, to: innerCols)
        let label = UILabel()
        label.font = .h3SemiBold
        label.textColor = .base800
        label.text = "/"
        innerCols.addArrangedSubview(label)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "bpDiastolic", attributeType: .integer, tag: &tag, to: innerCols)
        colB.addArrangedSubview(innerCols)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "heartRate", attributeType: .integer, unitText: " bpm", tag: &tag, to: colA)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "respiratoryRate", attributeType: .integer, unitText: " bpm", tag: &tag, to: colB)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "bloodGlucoseLevel", attributeType: .integer, tag: &tag, to: colA)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "cardiacRhythm",
                     attributeType: .custom(NemsisComboKeyboard(
                        source: EnumKeyboardSource<VitalCardiacRhythm>(),
                        isMultiSelect: true,
                        negatives: [
                            .notApplicable,
                            .refused,
                            .unabletoComplete
                        ])),
                     tag: &tag, to: colB)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "totalGlasgowComaScore", attributeType: .integer, tag: &tag, to: colA)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "pulseOximetry", attributeType: .integer, unitText: " %", tag: &tag, to: colB)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "endTidalCarbonDioxide", attributeType: .decimal, tag: &tag, to: colA)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "carbonMonoxide", attributeType: .decimal, unitText: " %", tag: &tag, to: colB)
        section.addArrangedSubview(cols)
        return (section, cols, colA, colB)
    }

    func newProceduresSection(_ i: Int, source: Procedure? = nil, target: Procedure? = nil,
                              tag: inout Int) -> (FormSection, UIStackView, UIStackView, UIStackView) {
        let (section, cols, colA, colB) = newSection()
        section.source = source
        section.sourceIndex = i
        section.target = target

        let header = newHeader("ReportViewController.procedures".localized,
                               subheaderText: "ReportViewController.optional".localized)
        section.addArrangedSubview(header)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "procedurePerformedAt", attributeType: .datetime, tag: &tag, to: colA)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "procedure",
                     attributeType: .custom(NemsisComboKeyboard(
                        field: "eProcedures.03",
                        sources: [SNOMEDKeyboardSource()],
                        isMultiSelect: false,
                        negatives: [
                            .notApplicable, .contraindicationNoted, .deniedByOrder, .refused, .unabletoComplete, .orderCriteriaNotMet
                        ],
                        isNegativeExclusive: false)),
                     tag: &tag, to: colB)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "responseToProcedure",
                     attributeType: .custom(NemsisComboKeyboard(
                        source: EnumKeyboardSource<ProcedureResponse>(),
                        isMultiSelect: false,
                        negatives: [
                            .notApplicable
                        ])),
                     tag: &tag, to: colB)
        section.addArrangedSubview(cols)
        return (section, cols, colA, colB)
    }

    func newMedicationsSection(_ i: Int, source: Medication? = nil, target: Medication? = nil,
                               tag: inout Int) -> (FormSection, UIStackView, UIStackView, UIStackView) {
        let (section, cols, colA, colB) = newSection()
        section.source = source
        section.sourceIndex = i
        section.target = target

        let header = newHeader("ReportViewController.medications".localized,
                               subheaderText: "ReportViewController.optional".localized)
        section.addArrangedSubview(header)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "medicationAdministeredAt", attributeType: .datetime, tag: &tag, to: colA)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "medication",
                     attributeType: .custom(NemsisComboKeyboard(
                        field: "eMedications.03",
                        sources: [RxNormKeyboardSource(includeSystem: true)],
                        isMultiSelect: false,
                        negatives: [
                            .notApplicable, .contraindicationNoted, .deniedByOrder, .medicationAllergy, .medicationAlreadyTaken,
                            .refused, .unabletoComplete, .orderCriteriaNotMet
                        ],
                        isNegativeExclusive: false,
                        includeSystem: true)),
                     tag: &tag, to: colA)
        addTextField(source: source, sourceIndex: i, target: target,
                     attributeKey: "responseToMedication",
                     attributeType: .custom(NemsisComboKeyboard(
                        source: EnumKeyboardSource<MedicationResponse>(),
                        isMultiSelect: false,
                        negatives: [
                            .notApplicable
                        ])),
                     tag: &tag, to: colA)
        section.addArrangedSubview(cols)
        return (section, cols, colA, colB)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for formField in formFields {
            formField.updateStyle()
        }
        var contentInset = scrollView.contentInset
        contentInset.bottom = recordButton.frame.height + 16
        scrollView.contentInset = contentInset
    }

    func removeSections(type: AnyClass, greaterThan count: Int) {
        var lastSection: FormSection?
        for view in containerView.arrangedSubviews {
            if let view = view as? FormSection, (view.source ?? view.target)?.isKind(of: type) ?? false {
                if view.sourceIndex ?? 0 >= count {
                    let fieldsToRemove = FormSection.fields(in: view)
                    formFields = formFields.filter { !fieldsToRemove.contains($0) }
                    if let button = view.findLastButton() {
                        button.removeFromSuperview()
                        lastSection?.addLastButton(button)
                    }
                    view.removeFromSuperview()
                } else {
                    lastSection = view
                }
            }
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            if report.realm != nil {
                newReport = Report(clone: report)
            } else {
                newReport = report
            }
        } else {
            if newReport?.vitals.count ?? 0 > report.vitals.count {
                removeSections(type: Vital.self, greaterThan: max(1, report.vitals.count))
            }
            if newReport?.procedures.count ?? 0 > report.procedures.count {
                removeSections(type: Procedure.self, greaterThan: max(1, report.procedures.count))
            }
            if newReport?.medications.count ?? 0 > report.medications.count {
                removeSections(type: Medication.self, greaterThan: max(1, report.medications.count))
            }
            newReport = nil
        }
        for formField in formFields {
            formField.isEditing = editing
            formField.isUserInteractionEnabled = editing
            if let source = formField.source {
                switch String(describing: type(of: source)) {
                case "Scene":
                    formField.target = newReport?.scene
                case "Time":
                    formField.target = newReport?.time
                case "Response":
                    formField.target = newReport?.response
                case "Narrative":
                    formField.target = newReport?.narrative
                case "Disposition":
                    formField.target = newReport?.disposition
                case "Patient":
                    formField.target = newReport?.patient
                case "Situation":
                    formField.target = newReport?.situation
                case "History":
                    formField.target = newReport?.history
                case "Vital":
                    if let index = formField.sourceIndex, index < newReport?.vitals.count ?? 0 {
                        formField.target = newReport?.vitals[index]
                    } else {
                        formField.target = nil
                    }
                case "Procedure":
                    if let index = formField.sourceIndex, index < newReport?.procedures.count ?? 0 {
                        formField.target = newReport?.procedures[index]
                    } else {
                        formField.target = nil
                    }
                case "Medication":
                    if let index = formField.sourceIndex, index < newReport?.medications.count ?? 0 {
                        formField.target = newReport?.medications[index]
                    } else {
                        formField.target = nil
                    }
                default:
                    break
                }
            } else {
                print("missing source for", formField.attributeKey)
            }
        }
    }

    func resetFormFields() {
        for formField in formFields {
            if let attributeKey = formField.attributeKey {
                formField.attributeValue = formField.source?.value(forKey: attributeKey) as? NSObject
            }
        }
    }

    func refreshFormFields() {
        for formField in formFields {
            if let attributeKey = formField.attributeKey, let target = formField.target {
                formField.attributeValue = target.value(forKey: attributeKey) as? NSObject
            }
        }
    }

    @objc func newVitalsPressed(_ button: PRKit.Button) {
        if !isEditing {
            guard let delegate = delegate else { return }
            delegate.reportViewControllerNeedsEditing(self)
        }
        guard let newReport = newReport else { return }
        let vital = Vital.newRecord()
        let i = newReport.vitals.count
        var tag = button.tag
        newReport.vitals.append(vital)

        guard let prevSection = FormSection.parent(of: button) else { return }
        guard let prevIndex = containerView.arrangedSubviews.firstIndex(of: prevSection) else { return }

        let (section, _, _, _) = newVitalsSection(i, target: vital, tag: &tag)
        containerView.insertArrangedSubview(section, at: prevIndex + 1)
        button.tag = tag
        button.removeFromSuperview()
        section.addLastButton(button)
    }

    @objc func addProcedurePressed(_ button: PRKit.Button) {
        if !isEditing {
            guard let delegate = delegate else { return }
            delegate.reportViewControllerNeedsEditing(self)
        }
        guard let newReport = newReport else { return }
        let procedure = Procedure.newRecord()
        let i = newReport.procedures.count
        var tag = button.tag
        newReport.procedures.append(procedure)

        guard let prevSection = FormSection.parent(of: button) else { return }
        guard let prevIndex = containerView.arrangedSubviews.firstIndex(of: prevSection) else { return }

        let (section, _, _, _) = newProceduresSection(i, target: procedure, tag: &tag)
        containerView.insertArrangedSubview(section, at: prevIndex + 1)
        button.tag = tag
        button.removeFromSuperview()
        section.addLastButton(button)
    }

    @objc func addMedicationPressed(_ button: PRKit.Button) {
        if !isEditing {
            guard let delegate = delegate else { return }
            delegate.reportViewControllerNeedsEditing(self)
        }
        guard let newReport = newReport else { return }
        let medication = Medication.newRecord()
        let i = newReport.medications.count
        var tag = button.tag
        newReport.medications.append(medication)

        guard let prevSection = FormSection.parent(of: button) else { return }
        guard let prevIndex = containerView.arrangedSubviews.firstIndex(of: prevSection) else { return }

        let (section, _, _, _) = newMedicationsSection(i, target: medication, tag: &tag)
        containerView.insertArrangedSubview(section, at: prevIndex + 1)
        button.tag = tag
        button.removeFromSuperview()
        section.addLastButton(button)
    }

    @IBAction func recordPressed() {
        if !isEditing {
            guard let delegate = delegate else { return }
            delegate.reportViewControllerNeedsEditing(self)
        }
        performSegue(withIdentifier: "Record", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? RecordingViewController {
            vc.delegate = self
        }
    }

    // MARK: - FormFieldDelegate

    func formFieldDidChange(_ field: PRKit.FormField) {
        if let attributeKey = field.attributeKey, let target = field.target {
            target.setValue(field.attributeValue, forKey: attributeKey)
        }
    }

    func formField(_ field: PRKit.FormField, wantsToPresent vc: UIViewController) {
        presentAnimated(vc)
    }

    // MARK: - RecordingViewControllerDelegate

    func recordingViewController(_ vc: RecordingViewController, didRecognizeText text: String,
                                 sourceId: String, metadata: [String: Any], isFinal: Bool) {
        if newReport == report {
            newReport?.narrative?.text = text
        } else {
            newReport?.narrative?.text = "\(report.narrative?.text ?? "") \(text)"
        }
        let formField = formFields.first(where: { $0.target == newReport?.narrative && $0.attributeKey == "text" })
        formField?.attributeValue = formField?.target?.value(forKey: "text") as? NSObject
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.newReport?.extractValues(from: text, sourceId: sourceId, metadata: metadata, isFinal: isFinal)
            DispatchQueue.main.async { [weak self] in
                self?.refreshFormFields()
            }
        }
    }

    func recordingViewController(_ vc: RecordingViewController, didFinishRecording fileURL: URL) {
//        AppRealm.uploadPatientAsset(patient: patient, key: Patient.Keys.audioFile, fileURL: fileURL)
    }

    func recordingViewController(_ vc: RecordingViewController, didThrowError error: Error) {
        switch error {
        case TranscriberError.speechRecognitionNotAuthorized:
            // even with speech recognition off, we can still allow a recording...
            vc.startRecording()
        default:
            dismiss(animated: true) { [weak self] in
                self?.presentAlert(error: error)
            }
        }
    }
}
