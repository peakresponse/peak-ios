//
//  ReportViewController.swift
//  Triage
//
//  Created by Francis Li on 11/4/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import UIKit
import Keyboardy
import RealmSwift

protocol ReportViewControllerDelegate: AnyObject {
    func reportViewControllerNeedsEditing(_ vc: ReportViewController)
}

class ReportViewController: UIViewController, FormViewController, KeyboardAwareScrollViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIStackView!
    var formInputAccessoryView: UIView!
    var formFields: [PRKit.FormField] = []

    var report: Report!
    var newReport: Report?
    var scene: Scene!
    var time: Time!
    var response: Response!
    var narrative: Narrative!
    var disposition: Disposition!
    var patient: Patient!
    var situation: Situation!
    var history: History!
    var vitals: [Vital]!
    var procedures: [Procedure]!
    var medications: [Medication]!

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

        scene = report.scene ?? Scene.newRecord()
        time = report.time ?? Time.newRecord()
        response = report.response ?? Response.newRecord()
        narrative = report.narrative ?? Narrative.newRecord()
        disposition = report.disposition ?? Disposition.newRecord()
        patient = report.patient ?? Patient.newRecord()
        situation = report.situation ?? Situation.newRecord()
        history = report.history ?? History.newRecord()
        vitals = Array(report.vitals)
        procedures = Array(report.procedures)
        medications = Array(report.medications)

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
//        innerCols = newColumns()
//        innerCols.addArrangedSubview(newButton(bundleImage: "Camera24px", title: "Button.scanLicense".localized))
//        innerCols.addArrangedSubview(newButton(bundleImage: "PatientAdd24px", title: "Button.addPatient".localized))
//        colA.addArrangedSubview(innerCols)
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
                        sources: [RxNormKeyboardSource()],
                        isMultiSelect: true,
                        negatives: [.notApplicable, .noKnownDrugAllergy, .refused, .unresponsive, .unabletoComplete])),
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

        for (i, vital) in vitals.enumerated() {
            (section, cols, colA, colB) = newVitalsSection(i, vital: vital, tag: &tag)
            containerView.addArrangedSubview(section)
        }
        var button = newButton(bundleImage: "Plus24px", title: "Button.newVitals".localized)
        button.addTarget(self, action: #selector(newVitalsPressed(_:)), for: .touchUpInside)
        button.tag = tag
        colA.addArrangedSubview(button)

        tag += 1000
        for (i, procedure) in procedures.enumerated() {
            (section, cols, colA, colB) = newSection()
            header = newHeader("ReportViewController.procedures".localized,
                               subheaderText: "ReportViewController.optional".localized)
            section.addArrangedSubview(header)
            addTextField(source: procedure, sourceIndex: i,
                         attributeKey: "procedurePerformedAt", attributeType: .datetime, tag: &tag, to: colA)
            addTextField(source: procedure, sourceIndex: i,
                         attributeKey: "procedure",
                         attributeType: .custom(NemsisComboKeyboard(
                            field: "eProcedures.03",
                            sources: [SNOMEDKeyboardSource()],
                            isMultiSelect: false,
                            negatives: [
                                .notApplicable, .contraindicationNoted, .deniedByOrder, .refused, .unabletoComplete, .orderCriteriaNotMet
                            ],
                            isNegativeExclusive: false)),
                         tag: &tag, to: colA)
            addTextField(source: procedure, sourceIndex: i,
                         attributeKey: "responseToProcedure",
                         attributeType: .custom(NemsisComboKeyboard(
                            source: EnumKeyboardSource<ProcedureResponse>(),
                            isMultiSelect: false,
                            negatives: [
                                .notApplicable
                            ])),
                         tag: &tag, to: colA)
            section.addArrangedSubview(cols)
            containerView.addArrangedSubview(section)
        }
        button = newButton(bundleImage: "Plus24px", title: "Button.addProcedure".localized)
        button.addTarget(self, action: #selector(addProcedurePressed), for: .touchUpInside)
        button.tag = tag
        colA.addArrangedSubview(button)

        tag += 1000
        for (i, medication) in medications.enumerated() {
            (section, cols, colA, colB) = newSection()
            header = newHeader("ReportViewController.medications".localized,
                               subheaderText: "ReportViewController.optional".localized)
            section.addArrangedSubview(header)
            addTextField(source: medication, sourceIndex: i,
                         attributeKey: "medicationAdministeredAt", attributeType: .datetime, tag: &tag, to: colA)
            addTextField(source: medication, sourceIndex: i,
                         attributeKey: "medication",
                         attributeType: .custom(NemsisComboKeyboard(
                            field: "eMedications.03",
                            sources: [RxNormKeyboardSource()],
                            isMultiSelect: false,
                            negatives: [
                                .notApplicable, .contraindicationNoted, .deniedByOrder, .medicationAllergy, .medicationAlreadyTaken,
                                .refused, .unabletoComplete, .orderCriteriaNotMet
                            ],
                            isNegativeExclusive: false)),
                         tag: &tag, to: colA)
            addTextField(source: medication, sourceIndex: i,
                         attributeKey: "responseToMedication",
                         attributeType: .custom(NemsisComboKeyboard(
                            source: EnumKeyboardSource<MedicationResponse>(),
                            isMultiSelect: false,
                            negatives: [
                                .notApplicable
                            ])),
                         tag: &tag, to: colA)
            section.addArrangedSubview(cols)
            containerView.addArrangedSubview(section)
        }
        button = newButton(bundleImage: "Plus24px", title: "Button.addMedication".localized)
        button.addTarget(self, action: #selector(addMedicationPressed), for: .touchUpInside)
        button.tag = tag
        colA.addArrangedSubview(button)

        setEditing(isEditing, animated: false)
    }

    func newVitalsSection(_ i: Int, vital: Vital, tag: inout Int) -> (UIStackView, UIStackView, UIStackView, UIStackView) {
        let (section, cols, colA, colB) = newSection()
        let header = newHeader("ReportViewController.vitals".localized,
                               subheaderText: "ReportViewController.optional".localized)
        section.addArrangedSubview(header)
        addTextField(source: vital, sourceIndex: i,
                     attributeKey: "vitalSignsTakenAt", attributeType: .datetime, tag: &tag, to: colA)
        let innerCols = newColumns()
        innerCols.distribution = .fillProportionally
        addTextField(source: vital, sourceIndex: i,
                     attributeKey: "bpSystolic", attributeType: .integer, tag: &tag, to: innerCols)
        let label = UILabel()
        label.font = .h3SemiBold
        label.textColor = .base800
        label.text = "/"
        innerCols.addArrangedSubview(label)
        addTextField(source: vital, sourceIndex: i,
                     attributeKey: "bpDiastolic", attributeType: .integer, tag: &tag, to: innerCols)
        colB.addArrangedSubview(innerCols)
        addTextField(source: vital, sourceIndex: i,
                     attributeKey: "heartRate", attributeType: .integer, unitText: " bpm", tag: &tag, to: colA)
        addTextField(source: vital, sourceIndex: i,
                     attributeKey: "respiratoryRate", attributeType: .integer, unitText: " bpm", tag: &tag, to: colB)
        addTextField(source: vital, sourceIndex: i,
                     attributeKey: "bloodGlucoseLevel", attributeType: .integer, tag: &tag, to: colA)
        addTextField(source: vital, sourceIndex: i,
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
        addTextField(source: vital, sourceIndex: i,
                     attributeKey: "totalGlasgowComaScore", attributeType: .integer, tag: &tag, to: colA)
        addTextField(source: vital, sourceIndex: i,
                     attributeKey: "pulseOximetry", attributeType: .integer, unitText: " %", tag: &tag, to: colB)
        addTextField(source: vital, sourceIndex: i,
                     attributeKey: "endTidalCarbonDioxide", attributeType: .decimal, tag: &tag, to: colA)
        addTextField(source: vital, sourceIndex: i,
                     attributeKey: "carbonMonoxide", attributeType: .decimal, unitText: " %", tag: &tag, to: colB)
        section.addArrangedSubview(cols)
        return (section, cols, colA, colB)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for formField in formFields {
            formField.updateStyle()
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
            if let source = formField.source, let attributeKey = formField.attributeKey {
                formField.attributeValue = source.value(forKey: attributeKey) as? NSObject
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

        guard var prevSection = button.superview else { return }
        while prevSection.superview != containerView {
            if let superview = prevSection.superview {
                prevSection = superview
            } else {
                return
            }
        }
        guard var prevIndex = containerView.arrangedSubviews.firstIndex(of: prevSection) else { return }
        prevIndex += 1

        let (section, _, colA, _) = newVitalsSection(i, vital: vital, tag: &tag)
        containerView.insertArrangedSubview(section, at: prevIndex)
        button.tag = tag
        button.removeFromSuperview()
        colA.addArrangedSubview(button)
    }

    @objc func addProcedurePressed() {

    }

    @objc func addMedicationPressed() {

    }

    // MARK: FormFieldDelegate

    func formFieldDidChange(_ field: PRKit.FormField) {
        if let attributeKey = field.attributeKey, let target = field.target {
            target.setValue(field.attributeValue, forKey: attributeKey)
        }
    }

    func formField(_ field: PRKit.FormField, wantsToPresent vc: UIViewController) {
        presentAnimated(vc)
    }
}
