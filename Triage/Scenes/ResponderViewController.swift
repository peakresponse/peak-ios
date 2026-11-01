//
//  ResponderViewController.swift
//  Triage
//
//  Created by Francis Li on 2/23/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

@objc protocol ResponderViewControllerDelegate {
    @objc optional func responderViewControllerDidSave(_ vc: ResponderViewController)
}

class ResponderViewController: BaseViewController, FormBuilder, KeyboardAwareScrollViewController, CheckboxDelegate {
    weak var commandHeader: CommandHeader!
    weak var scrollView: UIScrollView!
    weak var scrollViewBottomConstraint: NSLayoutConstraint!
    weak var containerView: UIStackView!

    var rightBarButtonItem: UIBarButtonItem!

    weak var delegate: ResponderViewControllerDelegate?

    var formInputAccessoryView: UIView!
    var formComponents: [String: PRKit.FormComponent] = [:]
    weak var doneButton: PRKit.Button!

    var responder: Responder!
    var newResponder: Responder?

    override func viewDidLoad() {
        super.viewDidLoad()

        let commandHeader = CommandHeader()
        commandHeader.translatesAutoresizingMaskIntoConstraints = false
        commandHeader.preservesSuperviewLayoutMargins = true
        headerView.addSubview(commandHeader)
        NSLayoutConstraint.activate([
            commandHeader.topAnchor.constraint(equalTo: headerView.topAnchor),
            commandHeader.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            commandHeader.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            commandHeader.contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            commandHeader.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            headerView.bottomAnchor.constraint(equalTo: commandHeader.bottomAnchor)
        ])
        self.commandHeader = commandHeader

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .background
        mainView.addSubview(scrollView)
        let scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: mainView.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            scrollViewBottomConstraint
        ])
        self.scrollView = scrollView
        self.scrollViewBottomConstraint = scrollViewBottomConstraint

        let containerView = UIStackView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.axis = .vertical
        containerView.alignment = .fill
        containerView.distribution = .fill
        containerView.spacing = 0
        scrollView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            containerView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        self.containerView = containerView

        rightBarButtonItem = UIBarButtonItem(title: "Button.done".localized, style: .done, target: self, action: #selector(donePressed))

        commandHeader.leftBarButtonItem = navigationItem.leftBarButtonItem
        commandHeader.rightBarButtonItem = rightBarButtonItem

        formInputAccessoryView = FormInputAccessoryView(rootView: view)

        let (section, cols, colA, colB) = newSection()
        var tag = 1

        addTextField(source: responder, attributeKey: "agency",
                     attributeType: .single(AgencyKeyboardSource()), tag: &tag, to: colA)
        addTextField(source: responder, attributeKey: "unitNumber",
                     attributeType: .integer, tag: &tag, to: colB)
        addTextField(source: responder, attributeKey: "callSign",
                     attributeType: .text, tag: &tag, to: colB)

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .top

        var radioGroup = newRadioGroup(source: responder, attributeKey: "status")
        radioGroup.addRadioButton(labelText: "Responder.status.arrived".localized, value: true as NSObject)
        radioGroup.addRadioButton(labelText: "Responder.status.enroute".localized, value: false as NSObject)
        stackView.addArrangedSubview(radioGroup)
        formComponents["status"] = radioGroup

        radioGroup = newRadioGroup(source: responder, attributeKey: "capability")
        radioGroup.isDeselectable = true
        radioGroup.addRadioButton(labelText: "Responder.capability.2207015".localized, value: ResponseUnitTransportAndEquipmentCapability.groundTransportAls.rawValue as NSObject)
        radioGroup.addRadioButton(labelText: "Responder.capability.2207017".localized, value: ResponseUnitTransportAndEquipmentCapability.groundTransportBls.rawValue as NSObject)
        stackView.addArrangedSubview(radioGroup)
        formComponents["capability"] = radioGroup

        colA.addArrangedSubview(stackView)

        let doneButton = newButton(title: "Button.done".localized)
        doneButton.size = .medium
        doneButton.addTarget(self, action: #selector(donePressed), for: .touchUpInside)
        colB.addArrangedSubview(UIView())
        colB.addArrangedSubview(doneButton)
        self.doneButton = doneButton

        section.addArrangedSubview(cols)

        containerView.addArrangedSubview(section)
        setEditing(isEditing, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for formField in formComponents.values {
            formField.updateStyle()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            if responder.realm != nil {
                newResponder = Responder(value: responder as Any)
            } else {
                newResponder = responder
            }
        } else if newResponder != nil {
            newResponder = nil
        }
        for formField in formComponents.values {
            formField.isEditing = editing
            formField.isEnabled = editing
            formField.target = newResponder
            if !editing {
                _ = formField.resignFirstResponder()
            }
        }
        if editing {
            _ = formComponents["agency"]?.becomeFirstResponder()
        }
    }

    @objc func donePressed() {
        guard let newResponder = newResponder else { return }

        if newResponder.agency == nil {
            presentAlert(title: "ResponderViewController.alert.agency.title".localized, message: "ResponderViewController.alert.agency.message".localized)
            return
        }
        if newResponder.identifier?.isEmpty ?? true {
            presentAlert(title: "ResponderViewController.alert.identifier.title".localized, message: "ResponderViewController.alert.identifier.message".localized)
            return
        }

        doneButton.isEnabled = false

        let spinner = UIActivityIndicatorView.withMediumStyle()
        spinner.color = .base500
        spinner.startAnimating()
        let spinnerItem = UIBarButtonItem(customView: spinner)
        commandHeader.rightBarButtonItem = spinnerItem

        AppRealm.addResponder(responder: newResponder) { [weak self] (error) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.doneButton.isEnabled = true
                self.commandHeader.rightBarButtonItem = self.rightBarButtonItem
                if let error = error as? ApiClientError, error == .conflict {
                    presentAlert(title: "ResponderViewController.alert.duplicate.title".localized, message: "ResponderViewController.alert.duplicate.message".localized)
                } else {
                    delegate?.responderViewControllerDidSave?(self)
                }
            }
        }
    }

    // MARK: - CheckboxDelegate

    func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        print(checkbox, isChecked)
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        if let attributeKey = component.attributeKey, let target = component.target {
            target.setValue(component.attributeValue, forKeyPath: attributeKey)
        }
    }
}
