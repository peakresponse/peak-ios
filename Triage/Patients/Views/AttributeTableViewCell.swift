//
//  AttributeTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

enum AttributeTableViewCellType: String {
    case string
    case number
    case object
    case age
    case gender
}

@objc protocol AttributeTableViewCellDelegate {
    @objc optional func attributeTableViewCell(_ cell: AttributeTableViewCell, didChange text: String,
                                               for attribute: String, with type: String)
    @objc optional func attributeTableViewCellDidPressAlert(_ cell: AttributeTableViewCell,
                                                            for attribute: String, with type: String)
    @objc optional func attributeTableViewCellDidReturn(_ cell: AttributeTableViewCell)
    @objc optional func attributeTableViewCellDidSelect(_ cell: AttributeTableViewCell)
}

class AttributeTableViewCell: BasePatientTableViewCell, FormFieldDelegate,
                              PatientAgeKeyboardViewDelegate, PatientGenderKeyboardViewDelegate {
    weak var stackView: UIStackView!
    var fields: [FormField] = []

    var attributes: [String]!
    var attributeTypes: [AttributeTableViewCellType]!
    weak var delegate: AttributeTableViewCellDelegate?
    weak var timer: Timer?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        layer.zPosition = -1
        backgroundColor = .clear
        selectionStyle = .none

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -22),
            contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 5)
        ])
        self.stackView = stackView
    }

    override func configure(from patient: Patient) {
        for field in fields {
            field.removeFromSuperview()
        }
        if fields.count < attributes.count {
            for _ in 0..<(attributes.count - fields.count) {
                let field = FormField()
                field.delegate = self
                fields.append(field)
            }
        }
        for (i, attribute) in attributes.enumerated() {
            let field = fields[i]
            stackView.addArrangedSubview(field)

            field.labelText = "Patient.\(attribute)".localized
            if let value = patient.value(forKey: attribute) {
                field.text = String(describing: value)
            } else {
                field.text = nil
            }

            field.textField.inputView = nil
            switch attributeTypes[i] {
            case .number:
                field.textField.keyboardType = .numberPad
            case .age:
                field.textField.inputView = PatientAgeKeyboardView(textField: field.textField,
                                                                   age: patient.age.value, units: patient.ageUnits)
            case .gender:
                field.textField.inputView = PatientGenderKeyboardView(textField: field.textField, value: patient.gender)
            default:
                field.textField.keyboardType = .default
            }
            field.textField.returnKeyType = .next
        }
    }

    func addAlertLabelTapRecognizer(to field: FormField) {
        if field.alertLabel.gestureRecognizers?.count ?? 0 == 0 {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(alertPressed(_:)))
            field.alertLabel.addGestureRecognizer(recognizer)
            field.alertLabel.isUserInteractionEnabled = true
        }
    }

    @objc private func alertPressed(_ sender: UILabel) {
        for (i, field) in fields.enumerated() where field.alertLabel == sender {
            delegate?.attributeTableViewCellDidPressAlert?(self, for: attributes[i], with: attributeTypes[i].rawValue)
            break
        }
    }

    func focusNext() -> Bool {
        let firstIndex = fields.firstIndex(where: {$0.isFirstResponder}) ?? 0
        for i in firstIndex..<fields.count {
            let field = fields[i]
            if !field.isFirstResponder && field.becomeFirstResponder() {
                return true
            }
        }
        return false
    }

    func focusPrev() -> Bool {
        let firstIndex = fields.firstIndex(where: {$0.isFirstResponder}) ?? fields.count - 1
        for i in (0...firstIndex).reversed() {
            let field = fields[i]
            if !field.isFirstResponder && field.becomeFirstResponder() {
                return true
            }
        }
        return false
    }

    override var isFirstResponder: Bool {
        for field in fields where field.isFirstResponder {
            return true
        }
        return false
    }

    override func becomeFirstResponder() -> Bool {
        for field in fields {
            if field.becomeFirstResponder() {
                return true
            }
        }
        return false
    }

    override func resignFirstResponder() -> Bool {
        for field in fields {
            if field.resignFirstResponder() {
                return true
            }
        }
        return false
    }

    // MARK: - UITableViewCell

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        for field in fields {
            field.textField.isUserInteractionEnabled = editing
            field.textField.rightViewMode = editing ? .always : .never
        }
    }

    // MARK: - FormFieldDelegate

    func formFieldShouldBeginEditing(_ field: BaseField) -> Bool {
        guard let field = field as? FormField, let i = fields.firstIndex(of: field) else { return false }
        if attributeTypes[i] == .object {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { [weak self] (_) in
                guard let self = self else { return }
                self.delegate?.attributeTableViewCellDidSelect?(self)
            })
            return false
        }
        return true
    }

    func formFieldDidBeginEditing(_ field: BaseField) {
        layer.zPosition = 0
    }

    func formFieldDidEndEditing(_ field: BaseField) {
        layer.zPosition = -1
    }

    func formFieldShouldReturn(_ field: BaseField) -> Bool {
        delegate?.attributeTableViewCellDidReturn?(self)
        return true
    }

    func formFieldDidChange(_ field: BaseField) {
        guard let field = field as? FormField, let i = fields.firstIndex(of: field) else { return }
        delegate?.attributeTableViewCell?(self, didChange: field.text ?? "", for: attributes[i], with: attributeTypes[i].rawValue)
    }

    // MARK: - PatientAgeKeyboardViewDelegate

    func patientAgeKeyboardView(_ view: PatientAgeKeyboardView, didSelect age: Int, units: String) {
        delegate?.attributeTableViewCell?(self, didChange: "\(age)",
                                          for: Patient.Keys.age, with: AttributeTableViewCellType.number.rawValue)
        delegate?.attributeTableViewCell?(self, didChange: units,
                                          for: Patient.Keys.ageUnits, with: AttributeTableViewCellType.string.rawValue)
    }

    // MARK: - PatientGenderKeyboardViewDelegate

    func patientGenderKeyboardView(_ view: PatientGenderKeyboardView, didSelect gender: String?) {
        delegate?.attributeTableViewCell?(self, didChange: gender ?? "",
                                          for: Patient.Keys.gender, with: AttributeTableViewCellType.string.rawValue)
    }
}
