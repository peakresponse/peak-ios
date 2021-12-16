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

class ReportViewController: UIViewController, PRKit.FormFieldDelegate, KeyboardAwareScrollViewController {
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
    var vitals: List<Vital>!
    var situation: Situation!
    var history: History!

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
        addTextField(source: response, target: nil, attributeKey: "incidentNumber",
                     keyboardType: .numbersAndPunctuation, tag: &tag, to: colA)
        addTextField(source: scene, target: nil, attributeKey: "address", tag: &tag, to: colA)
        addTextField(source: response, target: nil, attributeKey: "unitNumber", keyboardType: .numbersAndPunctuation, tag: &tag, to: colB)
        addTextField(source: time, target: nil, attributeKey: "unitNotifiedByDispatch", attributeType: .datetime, tag: &tag, to: colB)
        addTextField(source: time, target: nil, attributeKey: "arrivedAtPatient", attributeType: .datetime, tag: &tag, to: colB)
        addTextField(source: narrative, target: nil, attributeKey: "text", tag: &tag, to: colA)
        addTextField(source: disposition, target: nil,
                     attributeKey: "unitDisposition",
                     attributeType: .picker(EnumKeyboardSource<UnitDisposition>()),
                     tag: &tag, to: colB)

        var header = newHeader("Patient Information", subheaderText: " (optional)")
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
        addTextField(source: patient, target: nil, attributeKey: "firstName", tag: &tag, to: colA)
        addTextField(source: patient, target: nil, attributeKey: "lastName", tag: &tag, to: colB)
        addTextField(source: patient, target: nil, attributeKey: "dob", attributeType: .date, tag: &tag, to: colA)
        addAgeAndGender(tag: &tag, to: colB)
//        addPatientButtons(to: colA)

        header = newHeader("Medical Information", subheaderText: " (optional)")
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
        addTextField(source: situation, target: nil, attributeKey: "chiefComplaint", tag: &tag, to: colA)
        addTextField(source: situation, target: nil,
                     attributeKey: "primarySymptom",
                     attributeType: .custom(NemsisComboKeyboard(keyboards: [
                        NemsisKeyboard(field: "eSituation.09", sources: [ICD10CMKeyboardSource()], isMultiSelect: false),
                        NemsisNegativeKeyboard(negatives: [.notApplicable])
                     ], titles: [
                        "NemsisSearchKeyboard.title".localized,
                        "NemsisNegativeKeyboard.title".localized
                     ])),
                     tag: &tag, to: colB)
        addTextField(source: situation, target: nil,
                     attributeKey: "otherAssociatedSymptoms",
                     attributeType: .custom(NemsisKeyboard(field: "eSituation.10",
                                                           sources: [ICD10CMKeyboardSource()], isMultiSelect: true)),
                     tag: &tag, to: colB)
        addTextField(source: history, target: nil,
                     attributeKey: "medicalSurgicalHistory",
                     attributeType: .custom(NemsisKeyboard(field: "eHistory.08", sources: [ICD10CMKeyboardSource()], isMultiSelect: true)),
                     tag: &tag, to: colA)
        addTextField(source: history, target: nil,
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

        for vital in vitals {
            header = newHeader("Vitals", subheaderText: " (optional)")
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
            addTextField(source: vital, target: nil,
                         attributeKey: "vitalSignsTakenAt", attributeType: .datetime, tag: &tag, to: colA)
            let stackView = newColumns()
            stackView.distribution = .fillProportionally
            addTextField(source: vital, target: nil,
                         attributeKey: "bpSystolic", attributeType: .integer, tag: &tag, to: stackView)
            let label = UILabel()
            label.font = .h3SemiBold
            label.textColor = .base800
            label.text = "/"
            stackView.addArrangedSubview(label)
            addTextField(source: vital, target: nil,
                         attributeKey: "bpDiastolic", attributeType: .integer, tag: &tag, to: stackView)
            colB.addArrangedSubview(stackView)
            addTextField(source: vital, target: nil,
                         attributeKey: "heartRate", attributeType: .integer, unitLabel: " bpm", tag: &tag, to: colA)
            addTextField(source: vital, target: nil,
                         attributeKey: "respiratoryRate", attributeType: .integer, unitLabel: " bpm", tag: &tag, to: colB)
            addTextField(source: vital, target: nil,
                         attributeKey: "bloodGlucoseLevel", attributeType: .integer, tag: &tag, to: colA)
            addTextField(source: vital, target: nil,
                         attributeKey: "cardiacRhythm",
                         attributeType: .multi(EnumKeyboardSource<VitalCardiacRhythm>()),
                         tag: &tag, to: colB)
            addTextField(source: vital, target: nil,
                         attributeKey: "totalGlasgowComaScore", attributeType: .integer, tag: &tag, to: colA)
            addTextField(source: vital, target: nil,
                         attributeKey: "pulseOximetry", attributeType: .integer, unitLabel: " %", tag: &tag, to: colB)
            addTextField(source: vital, target: nil,
                         attributeKey: "endTidalCarbonDioxide", attributeType: .decimal, tag: &tag, to: colA)
            addTextField(source: vital, target: nil,
                         attributeKey: "carbonMonoxide", attributeType: .decimal, unitLabel: " %", tag: &tag, to: colB)
        }
        colA.addArrangedSubview(newButton(bundleImage: "Plus24px", title: "New Vitals"))

        header = newHeader("Interventions", subheaderText: " (optional)")
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
        addTextField(labelText: "Treatment/Dose/Route", to: colA)
        addTextField(labelText: "Patient Response", to: colB)
        colA.addArrangedSubview(newButton(bundleImage: "Plus24px", title: "Add Intervention"))

        /*
        header = newHeader("Additional Notes", subheaderText: " (optional)")
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
            cols.rightAnchor.constraint(equalTo: containerView.rightAnchor),
        ])
        addCheckbox(labelText: "COVID-19 suspected", to: colA)
        addCheckbox(labelText: "ETOH suspected", to: colA)
        addCheckbox(labelText: "Drugs suspected", to: colA)
        addCheckbox(labelText: "Psych patient", to: colA)
        addCheckbox(labelText: "Combative", to: colA)
        addTextField(labelText: "Other Notes", to: colB)
         */
        containerView.bottomAnchor.constraint(equalTo: cols.bottomAnchor, constant: 40).isActive = true
    }

    func addCheckbox(labelText: String, to col: UIStackView) {
        let checkbox = newCheckbox(labelText: labelText)
        col.addArrangedSubview(checkbox)
    }

    func addTextField(labelText: String, to col: UIStackView) {
        let textField = newTextField(labelText: labelText)
        col.addArrangedSubview(textField)
    }

    func addTextField(source: AnyObject, target: AnyObject?,
                      attributeKey: String, attributeType: FormFieldAttributeType = .text,
                      keyboardType: UIKeyboardType = .default,
                      unitLabel: String? = nil,
                      tag: inout Int, to col: UIStackView) {
        let textField = newTextField(source: source, target: target,
                                     attributeKey: attributeKey, attributeType: attributeType,
                                     keyboardType: keyboardType,
                                     unitLabel: unitLabel,
                                     tag: &tag)
        col.addArrangedSubview(textField)
    }

    func addAgeAndGender(tag: inout Int, to col: UIStackView) {
        let stackView = newColumns()
        addTextField(source: patient, target: nil,
                     attributeKey: "age",
                     attributeType: .integerWithUnit(EnumKeyboardSource<PatientAgeUnits>()),
                     tag: &tag, to: stackView)
        addTextField(source: patient, target: nil,
                     attributeKey: "gender",
                     attributeType: .picker(EnumKeyboardSource<PatientGender>()),
                     tag: &tag, to: stackView)
        col.addArrangedSubview(stackView)
    }

    func addPatientButtons(to col: UIStackView) {
        let stackView = newColumns()
        stackView.addArrangedSubview(newButton(bundleImage: "Camera24px", title: "Scan License"))
        stackView.addArrangedSubview(newButton(bundleImage: "PatientAdd24px", title: "Add Patient"))
        col.addArrangedSubview(stackView)
    }

    func newButton(bundleImage: String?, title: String?) -> PRKit.Button {
        let button = PRKit.Button()
        button.bundleImage = bundleImage
        button.setTitle(title, for: .normal)
        button.size = .small
        button.style = .primary
        return button
    }

    func newColumns() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        return stackView
    }

    func newCheckbox(labelText: String) -> PRKit.Checkbox {
        let checkbox = PRKit.Checkbox()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.labelText = labelText
        return checkbox
    }

    func newTextField(source: AnyObject, target: AnyObject?,
                      attributeKey: String, attributeType: FormFieldAttributeType = .text,
                      keyboardType: UIKeyboardType = .default,
                      unitLabel: String? = nil,
                      tag: inout Int) -> PRKit.TextField {
        let textField = PRKit.TextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.source = source
        textField.target = target
        textField.attributeKey = attributeKey
        textField.attributeType = attributeType
        textField.labelText = "\(String(describing: type(of: source))).\(attributeKey)".localized
        textField.attributeValue = source.value(forKey: attributeKey) as AnyObject?
        textField.inputAccessoryView = formInputAccessoryView
        textField.keyboardType = keyboardType
        if let unitLabel = unitLabel {
            textField.unitLabel.text = unitLabel
        }
        textField.tag = tag
        tag += 1
        textField.delegate = self
        return textField
    }

    func newTextField(labelText: String) -> PRKit.TextField {
        let textField = PRKit.TextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.labelText = labelText
        return textField
    }

    func newHeader(_ text: String, subheaderText: String?) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let header = UILabel()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.font = .h4SemiBold
        header.text = text
        header.textColor = .brandPrimary500
        view.addSubview(header)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leftAnchor.constraint(equalTo: view.leftAnchor)
        ])

        if let subheaderText = subheaderText {
            let subheader = UILabel()
            subheader.translatesAutoresizingMaskIntoConstraints = false
            subheader.font = .h4SemiBold
            subheader.text = subheaderText
            subheader.textColor = .base500
            view.addSubview(subheader)
            NSLayoutConstraint.activate([
                subheader.firstBaselineAnchor.constraint(equalTo: header.firstBaselineAnchor),
                subheader.leftAnchor.constraint(equalTo: header.rightAnchor),
                subheader.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor)
            ])
        } else {
            header.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor).isActive = true
        }

        let rule = UIView()
        rule.translatesAutoresizingMaskIntoConstraints = false
        rule.backgroundColor = .base300
        view.addSubview(rule)
        NSLayoutConstraint.activate([
            rule.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 3),
            rule.leftAnchor.constraint(equalTo: view.leftAnchor),
            rule.rightAnchor.constraint(equalTo: view.rightAnchor),
            rule.heightAnchor.constraint(equalToConstant: 2),
            view.bottomAnchor.constraint(equalTo: rule.bottomAnchor)
        ])
        return view
    }

    func newSection() -> (UIStackView, UIStackView, UIStackView) {
        let isRegular = traitCollection.horizontalSizeClass == .regular
        let colA = UIStackView()
        colA.translatesAutoresizingMaskIntoConstraints = false
        colA.axis = .vertical
        colA.alignment = .fill
        colA.distribution = .fill
        colA.spacing = 20
        let colB = isRegular ? UIStackView() : colA
        let cols = isRegular ? UIStackView() : colA
        if isRegular {
            colB.translatesAutoresizingMaskIntoConstraints = false
            colB.axis = .vertical
            colB.alignment = .fill
            colB.distribution = .fill
            colB.spacing = 20

            cols.translatesAutoresizingMaskIntoConstraints = false
            cols.axis = .horizontal
            cols.alignment = .top
            cols.distribution = .fillEqually
            cols.spacing = 20
            cols.addArrangedSubview(colA)
            cols.addArrangedSubview(colB)
        }
        return (cols, colA, colB)
    }

    // MARK: FormFieldDelegate

    func formField(_ field: PRKit.FormField, wantsToPresent vc: UIViewController) {
        presentAnimated(vc)
    }
}
