//
//  ReportViewController.swift
//  Triage
//
//  Created by Francis Li on 11/4/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import UIKit

class ReportViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    weak var containerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

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
        addTextField(labelText: "Incident #", to: colA)
        addTextField(labelText: "Date", to: colB)
        addTextField(labelText: "Location", to: colA)
        addTextField(labelText: "First Medical Contact", to: colB)
        addTextField(labelText: "Unit #", to: colB)
        addTextField(labelText: "Patient Disposition", to: colA)

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
        addTextField(labelText: "Age", to: colB)
        addTextField(labelText: "Gender", to: colB)

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
        addCheckbox(labelText: "Behavioral patient", to: colA)
        addCheckbox(labelText: "Combative", to: colA)
        addTextField(labelText: "Other Notes", to: colB)
    }

    func addCheckbox(labelText: String, to col: UIStackView) {
        let checkbox = PRKit.Checkbox()
        checkbox.labelText = labelText
        col.addArrangedSubview(checkbox)
    }

    func addTextField(labelText: String, to col: UIStackView) {
        let textField = PRKit.TextField()
        textField.labelText = labelText
        col.addArrangedSubview(textField)
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
