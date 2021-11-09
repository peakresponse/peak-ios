//
//  ReportViewController.swift
//  Triage
//
//  Created by Francis Li on 11/4/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import UIKit

class ReportViewController: UIViewController, PRKit.FormFieldDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    weak var containerView: UIView!

    var report: Report!
    var incident: Incident!
    var scene: Scene!
    var time: Time!

    override func viewDidLoad() {
        super.viewDidLoad()

        incident = report.incident
        scene = report.scene
        time = report.time

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(containerView)
        let widthConstraint = containerView.widthAnchor.constraint(equalToConstant: 690)
        widthConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            containerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            containerView.leftAnchor.constraint(greaterThanOrEqualTo: scrollView.leftAnchor, constant: 20),
            containerView.rightAnchor.constraint(lessThanOrEqualTo: scrollView.rightAnchor, constant: -20),
            widthConstraint,
            containerView.widthAnchor.constraint(lessThanOrEqualTo: scrollView.widthAnchor, constant: -40),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        self.containerView = containerView

        var (cols, colA, colB) = newSection()
        containerView.addSubview(cols)
        NSLayoutConstraint.activate([
            cols.topAnchor.constraint(equalTo: containerView.topAnchor),
            cols.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            cols.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            cols.widthAnchor.constraint(equalTo: containerView.widthAnchor)
        ])
        addTextField(source: incident, target: nil, attributeKey: "number", to: colA)
        addTextField(labelText: "Date", to: colB)
        addTextField(labelText: "Location", to: colA)
        addTextField(labelText: "First Medical Contact", to: colB)
        addTextField(labelText: "Unit #", to: colB)
        addTextField(labelText: "Narrative", to: colA)
        addTextField(labelText: "Disposition", to: colB)

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
            cols.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            cols.widthAnchor.constraint(equalTo: containerView.widthAnchor)
        ])
        addTextField(labelText: "First Name", to: colA)
        addTextField(labelText: "Last Name", to: colB)
        addTextField(labelText: "D.O.B", to: colA)
        addAgeAndGender(to: colB)
        addPatientButtons(to: colA)

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
            cols.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            cols.widthAnchor.constraint(equalTo: containerView.widthAnchor)
        ])
        addTextField(labelText: "Chief Complaint", to: colA)
        addTextField(labelText: "Signs/Symptoms", to: colB)
        addTextField(labelText: "Medical History", to: colA)
        addTextField(labelText: "Allergies", to: colB)

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
            cols.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            cols.widthAnchor.constraint(equalTo: containerView.widthAnchor)
        ])
        addTextField(labelText: "BP", to: colA)
        addTextField(labelText: "PR", to: colB)
        addTextField(labelText: "RR", to: colA)
        addTextField(labelText: "BGL", to: colB)
        addTextField(labelText: "EKG", to: colA)
        addTextField(labelText: "GCS", to: colB)
        addTextField(labelText: "SPO2", to: colA)
        addTextField(labelText: "EtCO2", to: colB)
        addTextField(labelText: "CO", to: colA)
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
            cols.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            cols.widthAnchor.constraint(equalTo: containerView.widthAnchor)
        ])
        addTextField(labelText: "Treatment/Dose/Route", to: colA)
        addTextField(labelText: "Patient Response", to: colB)
        colA.addArrangedSubview(newButton(bundleImage: "Plus24px", title: "Add Intervention"))

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
            cols.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            containerView.bottomAnchor.constraint(equalTo: cols.bottomAnchor, constant: 40)
        ])
        addCheckbox(labelText: "COVID-19 suspected", to: colA)
        addCheckbox(labelText: "ETOH suspected", to: colA)
        addCheckbox(labelText: "Drugs suspected", to: colA)
        addCheckbox(labelText: "Psych patient", to: colA)
        addCheckbox(labelText: "Combative", to: colA)
        addTextField(labelText: "Other Notes", to: colB)
    }

    func addCheckbox(labelText: String, to col: UIStackView) {
        let checkbox = newCheckbox(labelText: labelText)
        col.addArrangedSubview(checkbox)
    }

    func addTextField(labelText: String, to col: UIStackView) {
        let textField = newTextField(labelText: labelText)
        col.addArrangedSubview(textField)
    }

    func addTextField(source: AnyObject, target: AnyObject?, attributeKey: String, to col: UIStackView) {
        let textField = newTextField(source: source, target: target, attributeKey: attributeKey)
        col.addArrangedSubview(textField)
    }

    func addAgeAndGender(to col: UIStackView) {
        let stackView = newColumns()
        let age = newTextField(labelText: "Age")
        stackView.addArrangedSubview(age)
        let gender = newTextField(labelText: "Gender")
        stackView.addArrangedSubview(gender)
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
        button.size = .small
        button.style = .primary
        button.bundleImage = bundleImage
        button.setTitle(title, for: .normal)
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

    func newTextField(source: AnyObject, target: AnyObject?, attributeKey: String) -> PRKit.TextField {
        let textField = PRKit.TextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.source = source
        textField.target = target
        textField.attributeKey = attributeKey
        textField.labelText = "\(String(describing: type(of: source))).\(attributeKey)".localized
        textField.text = source.value(forKey: attributeKey) as? String
        textField.isUserInteractionEnabled = target != nil
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
        colA.spacing = 20
        let colB = isRegular ? UIStackView() : colA
        let cols = isRegular ? UIStackView() : colA
        if isRegular {
            colB.translatesAutoresizingMaskIntoConstraints = false
            colB.axis = .vertical
            colB.alignment = .fill
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
}
