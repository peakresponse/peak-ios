//
//  FormViewController.swift
//  Triage
//
//  Created by Francis Li on 9/15/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

@objc protocol FormViewControllerDelegate: AnyObject {
    @objc func formViewController(_ vc: FormViewController, didCollect signatures: [Signature])
    @objc optional func formViewController(_ vc: FormViewController, didDelete signatures: [Signature])
}

class FormViewController: UIViewController, FormBuilder, KeyboardAwareScrollViewController, CheckboxDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIStackView!

    weak var delegate: FormViewControllerDelegate?

    var formInputAccessoryView: UIView!
    var formFields: [String: PRKit.FormField] = [:]

    var form: Form!
    var report: Report!
    var newReport: Report?

    override func viewDidLoad() {
        super.viewDidLoad()

        commandHeader.leftBarButtonItem = navigationItem.leftBarButtonItem
        if isEditing {
            if commandHeader.leftBarButtonItem == nil {
                commandHeader.leftBarButtonItem = UIBarButtonItem(title: "Button.delete".localized, style: .plain, target: self, action: #selector(deletePressed))
            }
            commandHeader.rightBarButtonItem = UIBarButtonItem(title: "Button.done".localized, style: .done, target: self, action: #selector(donePressed))
        }

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

        formInputAccessoryView = FormInputAccessoryView(rootView: view)

        var (section, cols, colA, colB) = newSection()
        var header: UIView
        var tag = 1

        header = newHeader(form.title ?? "")
        section.addArrangedSubview(header)
        section.addArrangedSubview(newText(form.body ?? ""))
        containerView.addArrangedSubview(section)

        var reasons: [NemsisValue] = []
        if let reasonsData = form.reasons {
            for reason in reasonsData {
                reasons.append(NemsisValue(text: reason["code"] as? String))
            }
        }

        if report.signatures.isEmpty {
            let formInstanceId = UUID().uuidString.lowercased()
            if let signaturesData = form.signatures {
                for signatureData in signaturesData {
                    let signature = Signature.newRecord()
                    signature.form = form
                    signature.reason = reasons
                    signature.formInstanceId = formInstanceId
                    if let types = signatureData["types"] as? [String], types.count > 0 {
                        signature.typeOfPerson = types[0]
                    }
                    report.signatures.append(signature)
                }
            }
        }

        var signatureIndex = 0
        if let signaturesData = form.signatures {
            for signatureData in signaturesData {
                (section, cols, colA, colB) = newSection()
                header = newHeader(signatureData["title"] as? String ?? "")
                section.addArrangedSubview(header)
                if let body = signatureData["body"] as? String {
                    section.addArrangedSubview(newText(body))
                    section.addArrangedSubview(newVerticalSpacer())
                }
                tag = (signatureIndex + 1) * 1000
                let signatureField = SignatureField()
                signatureField.delegate = self
                signatureField.attributeKey = "signatures[\(signatureIndex)].file"
                signatureField.source = report
                signatureField.tag = tag
                tag += 1
                formFields[signatureField.attributeKey ?? ""] = signatureField
                if let fileUrl = report.signatures[signatureIndex].fileUrl {
                    AppCache.cachedImage(from: fileUrl) { (image, _) in
                        DispatchQueue.main.async {
                            signatureField.signatureImage = image
                        }
                    }
                }
                colA.addArrangedSubview(signatureField)
                if let types = signatureData["types"] as? [String], types.count > 1 {
                    let keyboardSource = EnumKeyboardSource<SignatureType>()
                    keyboardSource.filtered = types.map({ SignatureType(rawValue: $0) ?? .other })
                    addTextField(source: report, attributeKey: "signatures[\(signatureIndex)].typeOfPerson", attributeType: .single(keyboardSource), tag: &tag, to: colA)
                }
                addTextField(source: report, attributeKey: "signatures[\(signatureIndex)].status",
                             attributeType: .single(EnumKeyboardSource<SignatureStatus>()), tag: &tag, to: colB)
                addTextField(source: report, attributeKey: "signatures[\(signatureIndex)].dateTime",
                             attributeType: .datetime, tag: &tag, to: colB)
                addTextField(source: report, attributeKey: "signatures[\(signatureIndex)].typeOfPatientRepresentative",
                             attributeType: .single(EnumKeyboardSource<SignatureTypeOfPatientRepresentative>()), tag: &tag, to: colA)
                addTextField(source: report, attributeKey: "signatures[\(signatureIndex)].firstName", tag: &tag, to: colA)
                addTextField(source: report, attributeKey: "signatures[\(signatureIndex)].lastName", tag: &tag, to: colA)
                section.addArrangedSubview(cols)
                containerView.addArrangedSubview(section)
                signatureIndex += 1
            }
        }
        updateFormFieldVisibility()
        setEditing(isEditing, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for formField in formFields.values {
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
            if report.signatures.count > 0 && report.signatures[0].realm != nil {
                newReport = Report(clone: report)
            } else {
                newReport = report
            }
        } else if newReport != nil {
            self.newReport = nil
        }
        for formField in formFields.values {
            formField.isEditing = editing
            formField.isEnabled = editing
            formField.target = newReport
            if !editing {
                _ = formField.resignFirstResponder()
            }
        }
    }

    @objc func deletePressed() {
        if let signatures = newReport?.signatures {
            delegate?.formViewController?(self, didDelete: Array(signatures))
        }
    }

    @objc func donePressed() {
        if let signatures = newReport?.signatures {
            delegate?.formViewController(self, didCollect: Array(signatures))
        }
    }

    func refreshFormFields(_ attributeKeys: [String]? = nil) {
        if let attributeKeys = attributeKeys {
            for attributeKey in attributeKeys {
                if let formField = formFields[attributeKey], let target = formField.target {
                    formField.attributeValue = target.value(forKeyPath: attributeKey) as? NSObject
                }
            }
        } else {
            for formField in formFields.values {
                if let attributeKey = formField.attributeKey, let target = formField.target {
                    formField.attributeValue = target.value(forKeyPath: attributeKey) as? NSObject
                }
            }
        }
    }

    func updateFormFieldVisibility() {
        for (i, signature) in (newReport ?? report).signatures.enumerated() {
            if let formField = formFields["signatures[\(i)].typeOfPatientRepresentative"] {
                formField.isHidden = signature.typeOfPerson != SignatureType.patientRepresentative.rawValue
            }
            if let formField = formFields["signatures[\(i)].firstName"] {
                formField.isHidden = signature.typeOfPerson == nil || signature.typeOfPerson == SignatureType.patient.rawValue
            }
            if let formField = formFields["signatures[\(i)].lastName"] {
                formField.isHidden = signature.typeOfPerson == nil || signature.typeOfPerson == SignatureType.patient.rawValue
            }
        }
    }

    // MARK: - CheckboxDelegate

    func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        guard let target = newReport ?? report, let attributeKey = checkbox.attributeKey else { return }
        if isChecked {
            // uncheck other options in the group
            if let section = FormSection.parent(of: checkbox) {
                var radios: [Checkbox] = []
                FormSection.subviews(&radios, in: section)
                for radio in radios {
                    if radio != checkbox {
                        radio.isChecked = false
                    }
                }
            }
            // set the value in the corresponding signature record
            target.setValue(checkbox.value, forKeyPath: attributeKey)
        } else {
            target.setValue(nil, forKeyPath: attributeKey)
        }
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        if let field = component as? PRKit.FormField, let attributeKey = field.attributeKey, let target = field.target {
            if attributeKey.hasSuffix(".file"), let field = field as? SignatureField {
                if let signatureImage = field.signatureImage {
                    let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let tempFileURL = tempDirURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
                    target.setValue(tempFileURL.lastPathComponent, forKeyPath: attributeKey)
                    target.setValue(tempFileURL.absoluteString, forKeyPath: attributeKey.replacingOccurrences(of: ".file", with: ".fileUrl"))
                    target.setValue(tempFileURL.pathExtension, forKeyPath: attributeKey.replacingOccurrences(of: ".file", with: ".fileAttachmentType"))
                    if target.value(forKeyPath: attributeKey.replacingOccurrences(of: ".file", with: ".typeOfPerson")) as? String == SignatureType.patient.rawValue {
                        target.setValue(SignatureStatus.signed.rawValue, forKeyPath: attributeKey.replacingOccurrences(of: ".file", with: ".status"))
                    } else {
                        target.setValue(SignatureStatus.signedNotPatient.rawValue, forKeyPath: attributeKey.replacingOccurrences(of: ".file", with: ".status"))
                    }
                    target.setValue(Date(), forKeyPath: attributeKey.replacingOccurrences(of: ".file", with: ".dateTime"))
                    DispatchQueue.global().async { [weak self] in
                        if let signatureImageData = signatureImage.pngData() {
                            do {
                                try signatureImageData.write(to: tempFileURL, options: [.atomic])
                                AppRealm.uploadFile(fileURL: tempFileURL)
                            } catch {
                                self?.presentAlert(error: error)
                            }
                        }
                    }
                } else {
                    target.setValue(nil, forKeyPath: attributeKey)
                    target.setValue(nil, forKeyPath: attributeKey.replacingOccurrences(of: ".file", with: ".fileUrl"))
                    target.setValue(nil, forKeyPath: attributeKey.replacingOccurrences(of: ".file", with: ".fileAttachmentType"))
                    target.setValue(nil, forKeyPath: attributeKey.replacingOccurrences(of: ".file", with: ".status"))
                    target.setValue(nil, forKeyPath: attributeKey.replacingOccurrences(of: ".file", with: ".dateTime"))
                }
                refreshFormFields([attributeKey.replacingOccurrences(of: ".file", with: ".status"), attributeKey.replacingOccurrences(of: ".file", with: ".dateTime")])
            } else {
                target.setValue(field.attributeValue, forKeyPath: attributeKey)
                if attributeKey.hasSuffix(".typeOfPerson") {
                    updateFormFieldVisibility()
                }
            }
        }
    }

    func formField(_ field: PRKit.FormField, wantsToPresent vc: UIViewController) {
        presentAnimated(vc)
    }
}
