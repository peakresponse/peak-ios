//
//  ResponderRoleSelector.swift
//  Triage
//
//  Created by Francis Li on 5/29/22.
//

import PRKit
import UIKit

private class InternalTextField: UITextField {
    weak var selector: ResponderRoleSelector?

    override func becomeFirstResponder() -> Bool {
        if super.becomeFirstResponder() {
            selector?.updateStyle()
            selector?.reloadInputViews()
            return true
        }
        return false
    }

    override func resignFirstResponder() -> Bool {
        if super.resignFirstResponder() {
            selector?.updateStyle()
            return true
        }
        return false
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }
}

@IBDesignable
class ResponderRoleSelector: PRKit.FormField, UITextFieldDelegate {
    let textField: UITextField = InternalTextField()

    @IBInspectable override var text: String? {
        get { return textField.text }
        set { textField.text = newValue}
    }

    @IBInspectable var placeholderText: String? {
        get { return textField.placeholder }
        set { textField.placeholder = newValue }
    }

    override var inputView: UIView? {
        get { return textField.inputView }
        set { textField.inputView = newValue }
    }

    private var _inputAccessoryView: UIView?
    override var inputAccessoryView: UIView? {
        get { return _inputAccessoryView }
        set { _inputAccessoryView = newValue }
    }

    var role: ResponderRole?

    override func commonInit() {
        super.commonInit()

        isLabelHidden = true

        textField.delegate = self
        (textField as? InternalTextField)?.selector = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .h4SemiBold
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .valueChanged)
        contentView.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: -2),
            textField.leftAnchor.constraint(equalTo: label.leftAnchor),
            textField.rightAnchor.constraint(equalTo: label.rightAnchor),
            textField.heightAnchor.constraint(equalToConstant: round(textField.font!.lineHeight * 1.2)),
            contentView.bottomAnchor.constraint(equalTo: textField.bottomAnchor, constant: 10)
        ])

        placeholderText = "Responder.role.assign".localized

        let keyboard = SelectKeyboard(source: EnumKeyboardSource<ResponderRole>())
        keyboard.delegate = self
        inputView = keyboard
    }

    @objc func textFieldDidChange() {
        delegate?.formComponentDidChange?(self)
    }

    override func didUpdateAttributeValue() {
        super.didUpdateAttributeValue()
        _ = resignFirstResponder()
    }

    override func updateStyle() {
        super.updateStyle()
        textField.textColor = isEnabled ? .text : .disabledLabelText
    }

    override var canBecomeFirstResponder: Bool {
        return isEnabled && textField.canBecomeFirstResponder
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

    // MARK: - UITextFieldDelegate

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return (delegate as? PRKit.FormFieldDelegate)?.formFieldShouldBeginEditing?(self) ?? true
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        (delegate as? PRKit.FormFieldDelegate)?.formFieldDidBeginEditing?(self)
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return (delegate as? PRKit.FormFieldDelegate)?.formFieldShouldEndEditing?(self) ?? true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        (delegate as? PRKit.FormFieldDelegate)?.formFieldDidEndEditing?(self)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return (delegate as? PRKit.FormFieldDelegate)?.formFieldShouldReturn?(self) ?? true
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
}
