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

class ReportViewController: UIViewController, FormViewController, KeyboardAwareScrollViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    var formInputAccessoryView: UIView!

    var report: Report!
    var scene: Scene!
    var time: Time!
    var response: Response!
    var narrative: Narrative!
    var disposition: Disposition!
    var patient: Patient!
    var situation: Situation!
    var history: History!
    var vitals: List<Vital>!
    var procedures: List<Procedure>!

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

        scene = report.scene
        time = report.time
        response = report.response
        narrative = report.narrative
        disposition = report.disposition
        patient = report.patient
        vitals = report.vitals
        situation = report.situation
        history = report.history
        procedures = report.procedures

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

        var (cols, colA, colB) = newSection()
        containerView.addSubview(cols)
        NSLayoutConstraint.activate([
            cols.topAnchor.constraint(equalTo: containerView.topAnchor),
            cols.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            cols.rightAnchor.constraint(equalTo: containerView.rightAnchor)
        ])
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
                     attributeType: .picker(EnumKeyboardSource<UnitDisposition>()),
                     tag: &tag, to: colB)

        var header = newHeader("ReportViewController.patientInformation".localized,
                               subheaderText: "ReportViewController.optional".localized)
        containerView.addSubview(header)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: cols.bottomAnchor, constant: 40),
            header.leftAnchor.constraint(equalTo: cols.leftAnchor),
            header.rightAnchor.constraint(equalTo: cols.rightAnchor)
        ])
        (cols, colA, colB) = newSection()
        containerView.addSubview(cols)
        NSLayoutConstraint.activate([
            cols.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 20),
            cols.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            cols.rightAnchor.constraint(equalTo: containerView.rightAnchor)
        ])
        addTextField(source: patient, attributeKey: "firstName", tag: &tag, to: colA)
        addTextField(source: patient, attributeKey: "lastName", tag: &tag, to: colB)
        addTextField(source: patient, attributeKey: "dob", attributeType: .date, tag: &tag, to: colA)
        var innerCols = newColumns()
        addTextField(source: patient,
                     attributeKey: "age",
                     attributeType: .integerWithUnit(EnumKeyboardSource<PatientAgeUnits>()),
                     tag: &tag, to: innerCols)
        addTextField(source: patient,
                     attributeKey: "gender",
                     attributeType: .picker(EnumKeyboardSource<PatientGender>()),
                     tag: &tag, to: innerCols)
        colB.addArrangedSubview(innerCols)
//        innerCols = newColumns()
//        innerCols.addArrangedSubview(newButton(bundleImage: "Camera24px", title: "Button.scanLicense".localized))
//        innerCols.addArrangedSubview(newButton(bundleImage: "PatientAdd24px", title: "Button.addPatient".localized))
//        colA.addArrangedSubview(innerCols)

        header = newHeader("ReportViewController.medicalInformation".localized,
                           subheaderText: "ReportViewController.optional".localized)
        containerView.addSubview(header)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: cols.bottomAnchor, constant: 40),
            header.leftAnchor.constraint(equalTo: cols.leftAnchor),
            header.rightAnchor.constraint(equalTo: cols.rightAnchor)
        ])
        (cols, colA, colB) = newSection()
        containerView.addSubview(cols)
        NSLayoutConstraint.activate([
            cols.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 20),
            cols.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            cols.rightAnchor.constraint(equalTo: containerView.rightAnchor)
        ])
        addTextField(source: situation, attributeKey: "chiefComplaint", tag: &tag, to: colA)
        addTextField(source: situation,
                     attributeKey: "primarySymptom",
                     attributeType: .custom(NemsisComboKeyboard(keyboards: [
                        NemsisKeyboard(field: "eSituation.09", sources: [ICD10CMKeyboardSource()], isMultiSelect: false),
                        NemsisNegativeKeyboard(negatives: [.notApplicable])
                     ], titles: [
                        "NemsisSearchKeyboard.title".localized,
                        "NemsisNegativeKeyboard.title".localized
                     ])),
                     tag: &tag, to: colB)
        addTextField(source: situation,
                     attributeKey: "otherAssociatedSymptoms",
                     attributeType: .custom(NemsisKeyboard(field: "eSituation.10",
                                                           sources: [ICD10CMKeyboardSource()], isMultiSelect: true)),
                     tag: &tag, to: colB)
        addTextField(source: history,
                     attributeKey: "medicalSurgicalHistory",
                     attributeType: .custom(NemsisKeyboard(field: "eHistory.08", sources: [ICD10CMKeyboardSource()], isMultiSelect: true)),
                     tag: &tag, to: colA)
        addTextField(source: history,
                     attributeKey: "medicationAllergies",
                     attributeType: .custom(NemsisComboKeyboard(keyboards: [
                        NemsisKeyboard(field: "eHistory.06", sources: [RxNormKeyboardSource()], isMultiSelect: true),
                        NemsisNegativeKeyboard(negatives: [
                           .notApplicable, .noKnownDrugAllergy, .refused, .unresponsive, .unabletoComplete
                        ])
                     ], titles: [
                        "NemsisSearchKeyboard.title".localized,
                        "NemsisNegativeKeyboard.title".localized
                     ])),
                     tag: &tag, to: colA)
        addTextField(source: history,
                     attributeKey: "environmentalFoodAllergies",
                     attributeType: .custom(NemsisKeyboard(field: "eHistory.07", sources: [SNOMEDKeyboardSource()], isMultiSelect: true)),
                     tag: &tag, to: colB)

        for vital in vitals {
            header = newHeader("ReportViewController.vitals".localized,
                               subheaderText: "ReportViewController.optional".localized)
            containerView.addSubview(header)
            NSLayoutConstraint.activate([
                header.topAnchor.constraint(equalTo: cols.bottomAnchor, constant: 40),
                header.leftAnchor.constraint(equalTo: cols.leftAnchor),
                header.rightAnchor.constraint(equalTo: cols.rightAnchor)
            ])
            (cols, colA, colB) = newSection()
            containerView.addSubview(cols)
            NSLayoutConstraint.activate([
                cols.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 20),
                cols.leftAnchor.constraint(equalTo: containerView.leftAnchor),
                cols.rightAnchor.constraint(equalTo: containerView.rightAnchor)
            ])
            addTextField(source: vital,
                         attributeKey: "vitalSignsTakenAt", attributeType: .datetime, tag: &tag, to: colA)
            innerCols = newColumns()
            innerCols.distribution = .fillProportionally
            addTextField(source: vital,
                         attributeKey: "bpSystolic", attributeType: .integer, tag: &tag, to: innerCols)
            let label = UILabel()
            label.font = .h3SemiBold
            label.textColor = .base800
            label.text = "/"
            innerCols.addArrangedSubview(label)
            addTextField(source: vital,
                         attributeKey: "bpDiastolic", attributeType: .integer, tag: &tag, to: innerCols)
            colB.addArrangedSubview(innerCols)
            addTextField(source: vital,
                         attributeKey: "heartRate", attributeType: .integer, unitLabel: " bpm", tag: &tag, to: colA)
            addTextField(source: vital,
                         attributeKey: "respiratoryRate", attributeType: .integer, unitLabel: " bpm", tag: &tag, to: colB)
            addTextField(source: vital,
                         attributeKey: "bloodGlucoseLevel", attributeType: .integer, tag: &tag, to: colA)
            addTextField(source: vital,
                         attributeKey: "cardiacRhythm",
                         attributeType: .multi(EnumKeyboardSource<VitalCardiacRhythm>()),
                         tag: &tag, to: colB)
            addTextField(source: vital,
                         attributeKey: "totalGlasgowComaScore", attributeType: .integer, tag: &tag, to: colA)
            addTextField(source: vital,
                         attributeKey: "pulseOximetry", attributeType: .integer, unitLabel: " %", tag: &tag, to: colB)
            addTextField(source: vital,
                         attributeKey: "endTidalCarbonDioxide", attributeType: .decimal, tag: &tag, to: colA)
            addTextField(source: vital,
                         attributeKey: "carbonMonoxide", attributeType: .decimal, unitLabel: " %", tag: &tag, to: colB)
        }
        colA.addArrangedSubview(newButton(bundleImage: "Plus24px", title: "Button.newVitals".localized))

        for procedure in procedures {
            header = newHeader("ReportViewController.interventions".localized,
                               subheaderText: "ReportViewController.optional".localized)
            containerView.addSubview(header)
            NSLayoutConstraint.activate([
                header.topAnchor.constraint(equalTo: cols.bottomAnchor, constant: 40),
                header.leftAnchor.constraint(equalTo: cols.leftAnchor),
                header.rightAnchor.constraint(equalTo: cols.rightAnchor)
            ])
            (cols, colA, colB) = newSection()
            containerView.addSubview(cols)
            NSLayoutConstraint.activate([
                cols.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 20),
                cols.leftAnchor.constraint(equalTo: containerView.leftAnchor),
                cols.rightAnchor.constraint(equalTo: containerView.rightAnchor)
            ])
            addTextField(source: procedure,
                         attributeKey: "procedurePerformedAt", attributeType: .datetime, tag: &tag, to: colA)
            addTextField(source: procedure,
                         attributeKey: "procedure",
                         attributeType: .custom(NemsisComboKeyboard(keyboards: [
                            NemsisKeyboard(field: "eProcedures.03", sources: [SNOMEDKeyboardSource()], isMultiSelect: false),
                            NemsisNegativeKeyboard(negatives: [
                                .notApplicable, .contraindicationNoted, .deniedByOrder, .refused, .unabletoComplete, .orderCriteriaNotMet
                            ])
                         ], titles: [
                            "NemsisSearchKeyboard.title".localized,
                            "NemsisNegativeKeyboard.title".localized
                         ])),
                         tag: &tag, to: colA)
            addTextField(source: procedure,
                         attributeKey: "responseToProcedure",
                         attributeType: .picker(EnumKeyboardSource<ProcedureResponse>()),
                         tag: &tag, to: colA)
        }
        colA.addArrangedSubview(newButton(bundleImage: "Plus24px", title: "Button.addIntervention".localized))

        containerView.bottomAnchor.constraint(equalTo: cols.bottomAnchor, constant: 40).isActive = true
    }

    // MARK: FormFieldDelegate

    func formField(_ field: PRKit.FormField, wantsToPresent vc: UIViewController) {
        presentAnimated(vc)
    }
}
