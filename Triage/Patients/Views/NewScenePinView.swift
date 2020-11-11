//
//  NewScenePinView.swift
//  Triage
//
//  Created by Francis Li on 10/30/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation
import UIKit

protocol NewScenePinViewDelegate: class {
    func newScenePinView(_ view: NewScenePinView, didSelect pinType: ScenePinType)
    func newScenePinView(_ view: NewScenePinView, didChangeName name: String)
    func newScenePinView(_ view: NewScenePinView, didChangeDesc desc: String)
    func newScenePinViewDidCancel(_ view: NewScenePinView)
    func newScenePinViewDidSave(_ view: NewScenePinView)
}

class NewScenePinView: UIView, FormFieldDelegate {
    weak var scrollView: UIScrollView!
    var scrollViewContentHeightConstraint: NSLayoutConstraint!
    var scrollViewKeyboardHeightConstraint: NSLayoutConstraint!
    weak var label: UILabel!
    weak var buttonsView: UIView!
    var buttons: [ScenePinTypeButton]!
    weak var nameField: FormField!
    weak var descField: FormMultilineField!
    weak var cancelButton: FormButton!
    weak var saveButton: FormButton!

    weak var delegate: NewScenePinViewDelegate?

    var newPin: ScenePin!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        removeKeyboardListener()
    }

    // swiftlint:disable:next function_body_length
    private func commonInit() {
        addKeyboardListener()

        backgroundColor = .bgBackground
        addShadow(withOffset: CGSize(width: 0, height: 6), radius: 10, color: .mainGrey, opacity: 0.15)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollViewContentHeightConstraint =
            scrollView.frameLayoutGuide.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor)
        scrollViewKeyboardHeightConstraint = scrollView.frameLayoutGuide.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leftAnchor.constraint(equalTo: leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: rightAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            scrollViewContentHeightConstraint,
            bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
        self.scrollView = scrollView

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copyXSBold
        label.textColor = .greyPeakBlue
        label.text = "NewScenePinView.label".localized
        label.textAlignment = .center
        scrollView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 10),
            label.widthAnchor.constraint(equalToConstant: 252),
            label.centerXAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerXAnchor)
        ])
        self.label = label

        let buttonsView = UIView()
        buttonsView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(buttonsView)
        NSLayoutConstraint.activate([
            buttonsView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            buttonsView.widthAnchor.constraint(equalToConstant: 252),
            buttonsView.centerXAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerXAnchor)
        ])
        self.buttonsView = buttonsView

        buttons = []
        var prevButton: ScenePinTypeButton?
        for (i, pinType) in ScenePinType.allCases.enumerated() {
            let button = ScenePinTypeButton(size: .xxsmall, style: .priority)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            button.pinType = pinType
            buttonsView.addSubview(button)
            if i % 2 == 0 {
                NSLayoutConstraint.activate([
                    button.topAnchor.constraint(equalTo: prevButton?.bottomAnchor ?? buttonsView.topAnchor,
                                                constant: prevButton != nil ? 8 : 0),
                    button.leftAnchor.constraint(equalTo: buttonsView.leftAnchor),
                    button.widthAnchor.constraint(equalToConstant: 122)
                ])
            } else if let prevButton = prevButton {
                NSLayoutConstraint.activate([
                    button.topAnchor.constraint(equalTo: prevButton.topAnchor),
                    button.rightAnchor.constraint(equalTo: buttonsView.rightAnchor),
                    button.widthAnchor.constraint(equalToConstant: 122)
                ])
            }
            buttons.append(button)
            prevButton = button
        }
        if let prevButton = prevButton {
            NSLayoutConstraint.activate([
                buttonsView.bottomAnchor.constraint(equalTo: prevButton.bottomAnchor)
            ])
        }

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 10
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: buttonsView.bottomAnchor, constant: 10),
            stackView.leftAnchor.constraint(equalTo: buttonsView.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: buttonsView.rightAnchor)
        ])

        let nameField = FormField()
        nameField.delegate = self
        nameField.labelText = "NewScenePinView.nameField.label".localized
        nameField.isHidden = true
        stackView.addArrangedSubview(nameField)
        self.nameField = nameField

        let descField = FormMultilineField()
        descField.delegate = self
        descField.labelText = "NewScenePinView.descField.label".localized
        descField.isHidden = true
        stackView.addArrangedSubview(descField)
        self.descField = descField

        let cancelButton = FormButton(size: .xsmall, style: .lowPriority)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        cancelButton.buttonLabel = "Button.cancel".localized
        scrollView.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 24),
            cancelButton.widthAnchor.constraint(equalToConstant: 122),
            cancelButton.leftAnchor.constraint(equalTo: stackView.leftAnchor)
        ])
        self.cancelButton = cancelButton

        let saveButton = FormButton(size: .xsmall, style: .priority)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(savePressed), for: .touchUpInside)
        saveButton.buttonLabel = "Button.save".localized
        saveButton.isEnabled = false
        scrollView.addSubview(saveButton)
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 24),
            saveButton.widthAnchor.constraint(equalToConstant: 122),
            saveButton.rightAnchor.constraint(equalTo: stackView.rightAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 16)
        ])
        self.saveButton = saveButton
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // make sure shadow is only on bottom half of view so it doesn't appear on top of search box
        layer.shadowPath = UIBezierPath(rect: CGRect(x: 0, y: bounds.height / 2, width: bounds.width, height: bounds.height / 2)).cgPath
    }

    override func keyboardDidShow(_ notification: NSNotification) {
        if let frame = superview?.convert(self.frame, to: nil),
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            if keyboardFrame.minY < frame.maxY {
                scrollViewContentHeightConstraint.isActive = false
                scrollViewKeyboardHeightConstraint.constant = frame.height - floor(frame.maxY - keyboardFrame.minY)
                scrollViewKeyboardHeightConstraint.isActive = true
            }
        }
    }

    override func keyboardWillHide(_ notification: NSNotification) {
        scrollViewKeyboardHeightConstraint.isActive = false
        scrollViewContentHeightConstraint.isActive = true
    }

    @objc func cancelPressed() {
        delegate?.newScenePinViewDidCancel(self)
    }

    @objc func savePressed() {
        delegate?.newScenePinViewDidSave(self)
    }

    @objc func buttonPressed(_ sender: UIButton) {
        if let pinTypeButton = buttons.first(where: { $0.button == sender }),
           let pinType = pinTypeButton.pinType {
            delegate?.newScenePinView(self, didSelect: pinType)
            pinTypeButton.isSelected = true
            for button in buttons where button != pinTypeButton {
                button.isSelected = false
            }
            saveButton.isEnabled = true
            nameField.isHidden = pinType != .other
            descField.isHidden = false
        }
    }

    // MARK: - FormFieldDelegate

    func formFieldDidChange(_ field: BaseField) {
        if field == nameField {
            delegate?.newScenePinView(self, didChangeName: nameField.text ?? "")
        } else if field == descField {
            delegate?.newScenePinView(self, didChangeDesc: descField.text ?? "")
        }
    }

    func formFieldShouldReturn(_ field: BaseField) -> Bool {
        if field == nameField {
            _ = descField.becomeFirstResponder()
            scrollView.scrollRectToVisible(descField.convert(descField.bounds, to: scrollView), animated: true)
        } else if field == descField {
            _ = descField.resignFirstResponder()
        }
        return true
    }
}
