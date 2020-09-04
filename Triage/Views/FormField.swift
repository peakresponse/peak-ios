//
//  FormField.swift
//  Triage
//
//  Created by Francis Li on 8/4/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

enum FormFieldStatus: String {
    case none, unverified, verified
}

enum FormFieldStyle: String {
    case input, onboarding
}

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
class FormField: UIView, Localizable {
    let statusView = UIView()
    var statusViewWidthConstraint: NSLayoutConstraint!
    let label = UILabel()
    var labelTopConstraint: NSLayoutConstraint!
    let textField: UITextField = FormFieldTextField()
    var textFieldTopConstraint: NSLayoutConstraint!
    var textFieldHeightConstraint: NSLayoutConstraint!
    var bottomConstraint: NSLayoutConstraint!
    
    private var _detailLabel: UILabel!
    var detailLabel: UILabel {
        if (_detailLabel == nil) {
            initDetailLabel()
        }
        return _detailLabel
    }
    private var _alertLabel: UILabel!
    var alertLabel: UILabel {
        if (_alertLabel == nil) {
            initAlertLabel()
        }
        return _alertLabel
    }

    var status: FormFieldStatus = .none {
        didSet { updateStyle() }
    }
    
    var style: FormFieldStyle = .input {
        didSet { updateStyle() }
    }

    @IBInspectable var Style: String {
        get { return style.rawValue }
        set { style = FormFieldStyle(rawValue: newValue) ?? .input }
    }
    
    @IBOutlet weak var delegate: UITextFieldDelegate? {
        get { return textField.delegate }
        set { textField.delegate = newValue }
    }
    
    @IBInspectable var isEnabled: Bool {
        get { return textField.isEnabled }
        set { textField.isEnabled = newValue }
    }
    
    @IBInspectable var l10nKey: String? {
        get { return nil }
        set { label.l10nKey = newValue }
    }

    @IBInspectable var labelText: String? {
        get { return label.text }
        set { label.text = newValue }
    }
    
    @IBInspectable var text: String? {
        get { return textField.text }
        set { textField.text = newValue }
    }

    @IBInspectable var isSecureTextEntry: Bool {
        get { return textField.isSecureTextEntry }
        set { textField.isSecureTextEntry = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .white
        addShadow(withOffset: CGSize(width: 0, height: 2), radius: 3, color: .black, opacity: 0.15)

        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.backgroundColor = .middlePeakBlue
        addSubview(statusView)

        label.translatesAutoresizingMaskIntoConstraints = false;
        label.textColor = .lowPriorityGrey
        addSubview(label)
        
        (textField as? FormFieldTextField)?.formField = self
        textField.translatesAutoresizingMaskIntoConstraints = false;
        textField.textColor = .mainGrey
        textField.clearButtonMode = .never
        textField.rightViewMode = .whileEditing
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "Clear"), for: .normal)
        button.addTarget(self, action: #selector(clearPressed), for: .touchUpInside)
        textField.rightView = button
        addSubview(textField)

        statusViewWidthConstraint = statusView.widthAnchor.constraint(equalToConstant: 8)
        labelTopConstraint = label.topAnchor.constraint(equalTo: topAnchor, constant: 6)
        textFieldTopConstraint = textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10)
        textFieldHeightConstraint = textField.heightAnchor.constraint(equalToConstant: round(textField.font!.lineHeight * 1.2))
        bottomConstraint = bottomAnchor.constraint(equalTo: textField.bottomAnchor, constant: 14)

        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: topAnchor),
            statusView.leftAnchor.constraint(equalTo: leftAnchor),
            statusView.bottomAnchor.constraint(equalTo: bottomAnchor),
            statusViewWidthConstraint,
            labelTopConstraint,
            label.leftAnchor.constraint(equalTo: statusView.rightAnchor, constant: 10),
            textFieldTopConstraint,
            textField.leftAnchor.constraint(equalTo: statusView.rightAnchor, constant: 10),
            textField.rightAnchor.constraint(equalTo: rightAnchor, constant: -10),
            textFieldHeightConstraint,
            bottomConstraint
        ])

        updateStyle()
    }

    @objc private func clearPressed() {
        if textField.delegate?.textFieldShouldClear?(textField) ?? true {
            textField.text = nil
        }
    }

    private func initAlertLabel() {
        _alertLabel = UILabel()
        _alertLabel.translatesAutoresizingMaskIntoConstraints = false
        _alertLabel.font = .copyXSBold
        _alertLabel.textColor = .orangeAccent
        addSubview(_alertLabel)
        NSLayoutConstraint.activate([
            _alertLabel.topAnchor.constraint(equalTo: label.topAnchor),
            _alertLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10)
        ])
    }

    private func initDetailLabel() {
        _detailLabel = UILabel()
        _detailLabel.translatesAutoresizingMaskIntoConstraints = false
        _detailLabel.font = .copyXSRegular
        _detailLabel.textColor = .mainGrey
        addSubview(_detailLabel)
        NSLayoutConstraint.activate([
            _detailLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10),
            _detailLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3)
        ])
    }

    fileprivate func updateStyle() {
        switch style {
        case .input:
            label.font = .copyXSBold
            if textField.isFirstResponder {
                textField.font = .copyLBold
                if status == .none {
                    statusViewWidthConstraint.constant = 0
                } else {
                    statusViewWidthConstraint.constant = 22
                }
                labelTopConstraint.constant = 8
                textFieldTopConstraint.constant = 6
                bottomConstraint.constant = 16
            } else {
                textField.font = .copyMBold
                if status == .none {
                    statusViewWidthConstraint.constant = 0
                } else {
                    statusViewWidthConstraint.constant = 8
                }
                labelTopConstraint.constant = 4
                textFieldTopConstraint.constant = 4
                bottomConstraint.constant = 12
            }
        case .onboarding:
            label.font = .copySBold
            textField.font = .copyLBold
            statusViewWidthConstraint.constant = 0
            labelTopConstraint.constant = 8
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
}
