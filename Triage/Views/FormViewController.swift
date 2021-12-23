//
//  FormViewController.swift
//  Triage
//
//  Created by Francis Li on 12/21/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import UIKit

protocol FormViewController: PRKit.FormFieldDelegate {
    var traitCollection: UITraitCollection { get }
    var formInputAccessoryView: UIView! { get }
    var formFields: [PRKit.FormField] { get set }

    func newButton(bundleImage: String?, title: String?) -> PRKit.Button
    func newColumns() -> UIStackView
    func newHeader(_ text: String, subheaderText: String?) -> UIView
    func newSection() -> (UIStackView, UIStackView, UIStackView)
    func newTextField(source: AnyObject, sourceIndex: Int?,
                      attributeKey: String, attributeType: FormFieldAttributeType,
                      keyboardType: UIKeyboardType,
                      unitLabel: String?,
                      tag: inout Int) -> PRKit.TextField

    func addTextField(source: AnyObject, sourceIndex: Int?,
                      attributeKey: String, attributeType: FormFieldAttributeType,
                      keyboardType: UIKeyboardType,
                      unitLabel: String?,
                      tag: inout Int, to col: UIStackView)
}

extension FormViewController {
    func addTextField(source: AnyObject, sourceIndex: Int? = nil,
                      attributeKey: String, attributeType: FormFieldAttributeType = .text,
                      keyboardType: UIKeyboardType = .default,
                      unitLabel: String? = nil,
                      tag: inout Int, to col: UIStackView) {
        let textField = newTextField(source: source, sourceIndex: sourceIndex,
                                     attributeKey: attributeKey, attributeType: attributeType,
                                     keyboardType: keyboardType,
                                     unitLabel: unitLabel,
                                     tag: &tag)
        col.addArrangedSubview(textField)
        formFields.append(textField)
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

    func newTextField(source: AnyObject, sourceIndex: Int? = nil,
                      attributeKey: String, attributeType: FormFieldAttributeType = .text,
                      keyboardType: UIKeyboardType = .default,
                      unitLabel: String? = nil,
                      tag: inout Int) -> PRKit.TextField {
        let textField = PRKit.TextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.source = source
        textField.sourceIndex = sourceIndex
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

}
