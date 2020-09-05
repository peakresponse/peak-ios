//
//  FormField.swift
//  Triage
//
//  Created by Francis Li on 8/4/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

private class FormFieldTextField: UITextField {
    weak var formField: FormField?

    override func becomeFirstResponder() -> Bool {
        if super.becomeFirstResponder() {
            formField?.updateStyle()
            return true
        }
        return false
    }

    override func resignFirstResponder() -> Bool {
        if super.resignFirstResponder() {
            formField?.updateStyle()
            return true
        }
        return false
    }
}

@IBDesignable
class FormField: BaseField, UITextFieldDelegate {
    let textField: UITextField = FormFieldTextField()
    var textFieldTopConstraint: NSLayoutConstraint!
    var textFieldHeightConstraint: NSLayoutConstraint!
    var bottomConstraint: NSLayoutConstraint!
    
    @IBInspectable var isEnabled: Bool {
        get { return textField.isEnabled }
        set { textField.isEnabled = newValue }
    }
    
    @IBInspectable override var text: String? {
        get { return textField.text }
        set { textField.text = newValue }
    }

    override var inputAccessoryView: UIView? {
        get { return textField.inputAccessoryView }
        set { textField.inputAccessoryView = newValue }
    }
    
    @IBInspectable var isSecureTextEntry: Bool {
        get { return textField.isSecureTextEntry }
        set { textField.isSecureTextEntry = newValue }
    }
    
    override func commonInit() {
        super.commonInit()
        
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        (textField as? FormFieldTextField)?.formField = self
        textField.translatesAutoresizingMaskIntoConstraints = false;
        textField.textColor = .mainGrey
        textField.clearButtonMode = .never
        textField.rightViewMode = .whileEditing
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "Clear"), for: .normal)
        button.addTarget(self, action: #selector(clearPressed), for: .touchUpInside)
        textField.rightView = button
        contentView.addSubview(textField)

        textFieldTopConstraint = textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10)
        textFieldHeightConstraint = textField.heightAnchor.constraint(equalToConstant: round(textField.font!.lineHeight * 1.2))
        bottomConstraint = contentView.bottomAnchor.constraint(equalTo: textField.bottomAnchor, constant: 14)

        NSLayoutConstraint.activate([
            textFieldTopConstraint,
            textField.leftAnchor.constraint(equalTo: statusView.rightAnchor, constant: 10),
            textField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10),
            textFieldHeightConstraint,
            bottomConstraint
        ])
    }

    @objc private func clearPressed() {
        if textField.delegate?.textFieldShouldClear?(textField) ?? true {
            textField.text = nil
        }
    }

    override func updateStyle() {
        super.updateStyle()
        switch style {
        case .input:
            if isFirstResponder {
                textField.font = .copyLBold
                textFieldTopConstraint.constant = 6
                bottomConstraint.constant = 16

                let dy: CGFloat = 5 + (round(UIFont.copyLBold.lineHeight * 1.2) - round(UIFont.copyMBold.lineHeight * 1.2)) / 2
                contentViewConstraints[0].constant = -dy
                contentViewConstraints[3].constant = -dy
            } else {
                textField.font = .copyMBold
                textFieldTopConstraint.constant = 4
                bottomConstraint.constant = 12

                contentViewConstraints[0].constant = 0
                contentViewConstraints[3].constant = 0
            }
        case .onboarding:
            textField.font = .copyLBold
            textFieldTopConstraint.constant = 10
            bottomConstraint.constant = 14
        }
        textFieldHeightConstraint.constant = round(textField.font!.lineHeight * 1.2)
    }

    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    @objc func textFieldChanged() {
        delegate?.formFieldDidChange?(self)
    }
    
    // MARK: - UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return delegate?.formFieldShouldBeginEditing?(self) ?? true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.formFieldDidBeginEditing?(self)
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return delegate?.formFieldShouldEndEditing?(self) ?? true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.formFieldDidEndEditing?(self)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return delegate?.formFieldShouldReturn?(self) ?? true
    }
}
