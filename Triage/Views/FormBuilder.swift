//
//  FormBuilder.swift
//  Triage
//
//  Created by Francis Li on 12/21/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import UIKit

open class FormSection: UIStackView {
    open var type: AnyClass?
    open var index: Int?

    open var cols: UIStackView!
    open var colA: UIStackView!
    open var colB: UIStackView!

    public static func parent(of view: UIView) -> FormSection? {
        var superview = view.superview
        while superview != nil {
            if let superview = superview as? FormSection {
                return superview
            }
            superview = superview?.superview
        }
        return nil
    }

    public static func subviews<T>(_ subviews: inout [T], in view: UIView) {
        for subview in view.subviews {
            if let subview = subview as? T {
                subviews.append(subview)
            } else {
                FormSection.subviews(&subviews, in: subview)
            }
        }
    }

    public static func fields(in view: UIView) -> [PRKit.FormField] {
        var fields: [PRKit.FormField] = []
        FormSection.fields(in: view, fields: &fields)
        return fields
    }

    static func fields(in view: UIView, fields: inout [PRKit.FormField]) {
        for subview in view.subviews {
            if let subview = subview as? PRKit.FormField {
                fields.append(subview)
            } else {
                FormSection.fields(in: subview, fields: &fields)
            }
        }
    }

    func addLastButton(_ button: PRKit.Button) {
        var stackView = arrangedSubviews.last as? UIStackView
        if stackView?.axis == .horizontal {
            stackView = stackView?.arrangedSubviews.first as? UIStackView
        }
        stackView?.addArrangedSubview(button)
    }

    func findLastButton() -> PRKit.Button? {
        var stackView = arrangedSubviews.last as? UIStackView
        if stackView?.axis == .horizontal {
            stackView = stackView?.arrangedSubviews.first as? UIStackView
        }
        return stackView?.arrangedSubviews.last as? PRKit.Button
    }
}

public protocol FormBuilder: PRKit.FormFieldDelegate {
    var traitCollection: UITraitCollection { get }
    var formInputAccessoryView: UIView! { get }
    var formComponents: [String: PRKit.FormComponent] { get set }

    func refreshFormFields(attributeKeys: [String]?)

    func addTextField(source: NSObject?, target: NSObject?,
                      attributeKey: String, attributeType: FormFieldAttributeType,
                      keyboardType: UIKeyboardType,
                      unitText: String?,
                      tag: inout Int,
                      to col: UIStackView, withWrapper: Bool)

    func newButton(bundleImage: String?, title: String?) -> PRKit.Button
    func newColumns() -> UIStackView
    func newHeader(_ text: String, subheaderText: String?) -> UIView
    func newSection() -> (FormSection, UIStackView, UIStackView, UIStackView)
    func newVerticalSpacer(_ height: CGFloat) -> UIView
    func newText(_ text: String) -> UILabel
    func newTextField(source: NSObject?, target: NSObject?,
                      attributeKey: String, attributeType: FormFieldAttributeType,
                      keyboardType: UIKeyboardType,
                      unitText: String?,
                      tag: inout Int) -> PRKit.TextField
}

extension FormBuilder {
    func refreshFormFields(attributeKeys: [String]? = nil) {
        if let attributeKeys = attributeKeys {
            for attributeKey in attributeKeys {
                if let formComponent = formComponents[attributeKey], let target = formComponent.target ?? formComponent.source {
                    formComponent.attributeValue = target.value(forKeyPath: attributeKey) as? NSObject
                    if let formField = formComponent as? PRKit.FormField, let target = (formField.target ?? formField.source) as? Predictions {
                        formField.status = target.predictionStatus(for: attributeKey)
                    }
                }
            }
        } else {
            for formComponent in formComponents.values {
                if let attributeKey = formComponent.attributeKey, let target = formComponent.target ?? formComponent.source {
                    formComponent.attributeValue = target.value(forKeyPath: attributeKey) as? NSObject
                    if let formField = formComponent as? PRKit.FormField, let target = (formField.target ?? formField.source) as? Predictions {
                        formField.status = target.predictionStatus(for: attributeKey)
                    }
                }
            }
        }
    }

    func addTextField(source: NSObject? = nil, target: NSObject? = nil,
                      attributeKey: String, attributeType: FormFieldAttributeType = .text,
                      keyboardType: UIKeyboardType = .default,
                      unitText: String? = nil,
                      tag: inout Int,
                      to col: UIStackView, withWrapper: Bool = false) {
        let textField = newTextField(source: source, target: target,
                                     attributeKey: attributeKey, attributeType: attributeType,
                                     keyboardType: keyboardType,
                                     unitText: unitText,
                                     tag: &tag)
        if withWrapper {
            let wrapper = UIView()
            wrapper.translatesAutoresizingMaskIntoConstraints = false
            wrapper.addSubview(textField)
            NSLayoutConstraint.activate([
                textField.topAnchor.constraint(equalTo: wrapper.topAnchor),
                textField.leftAnchor.constraint(equalTo: wrapper.leftAnchor),
                textField.rightAnchor.constraint(equalTo: wrapper.rightAnchor),
                textField.bottomAnchor.constraint(lessThanOrEqualTo: wrapper.bottomAnchor)
            ])
            col.addArrangedSubview(wrapper)
        } else {
            col.addArrangedSubview(textField)
        }
        formComponents[attributeKey] = textField
    }

    func newVerticalSpacer(_ height: CGFloat = 20) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    func newText(_ text: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = text
        label.font = .h4SemiBold
        label.textColor = .base800
        return label
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

    func newTextField(source: NSObject? = nil, target: NSObject? = nil,
                      attributeKey: String, attributeType: FormFieldAttributeType = .text,
                      keyboardType: UIKeyboardType = .default,
                      unitText: String? = nil,
                      tag: inout Int) -> PRKit.TextField {
        let textField = PRKit.TextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.source = source
        textField.target = target
        textField.attributeKey = attributeKey
        textField.attributeType = attributeType
        let obj = source ?? target
        if let index = attributeKey.lastIndex(of: ".") {
            let child = obj?.value(forKeyPath: String(attributeKey[attributeKey.startIndex..<index])) as? NSObject
            let childAttributeKey = attributeKey[attributeKey.index(after: index)..<attributeKey.endIndex]
            textField.labelText = "\(String(describing: type(of: child ?? NSNull()))).\(childAttributeKey)".localized
        } else {
            textField.labelText = "\(String(describing: type(of: obj ?? NSNull()))).\(attributeKey)".localized
        }
        textField.attributeValue = obj?.value(forKeyPath: attributeKey) as? NSObject
        if let obj = obj as? Predictions {
            textField.status = obj.predictionStatus(for: attributeKey)
        }
        textField.inputAccessoryView = formInputAccessoryView
        textField.keyboardType = keyboardType
        if let unitText = unitText {
            textField.unitText = unitText
        }
        textField.tag = tag
        tag += 1
        textField.delegate = self
        return textField
    }

    func newHeader(_ text: String, subheaderText: String? = nil) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let header = UILabel()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.font = .h4SemiBold
        header.text = text
        header.textColor = .brandPrimary500
        header.numberOfLines = 0
        view.addSubview(header)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
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
            view.bottomAnchor.constraint(equalTo: rule.bottomAnchor, constant: 20)
        ])
        return view
    }

    func newSection() -> (FormSection, UIStackView, UIStackView, UIStackView) {
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
        let section = FormSection()
        section.translatesAutoresizingMaskIntoConstraints = false
        section.axis = .vertical
        section.alignment = .fill
        section.distribution = .fill
        section.spacing = 0
        section.cols = cols
        section.colA = colA
        section.colB = colB
        return (section, cols, colA, colB)
    }
}
