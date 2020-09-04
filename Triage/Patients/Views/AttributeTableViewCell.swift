//
//  AttributeTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

@objc protocol AttributeTableViewCellDelegate {
    @objc optional func attributeTableViewCell(_ cell: AttributeTableViewCell, didChange text: String)
    @objc optional func attributeTableViewCellDidReturn(_ cell: AttributeTableViewCell)
    @objc optional func attributeTableViewCellDidSelect(_ cell: AttributeTableViewCell)
    @objc optional func attributeTableViewCellDidPressAlert(_ cell: AttributeTableViewCell)
}

enum AttributeTableViewCellType {
    case string
    case number
    case object
}

class AttributeTableViewCell: PatientTableViewCell, UITextFieldDelegate {
    let field = FormField()

    var attribute: String!
    var attributeType: AttributeTableViewCellType = .string
    weak var delegate: AttributeTableViewCellDelegate?
    weak var timer: Timer?

    override var inputAccessoryView: UIView? {
        get { return field.textField.inputAccessoryView }
        set { field.textField.inputAccessoryView = newValue }
    }

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

        field.translatesAutoresizingMaskIntoConstraints = false
        field.delegate = self
        contentView.addSubview(field)
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            field.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            field.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -22),
            contentView.bottomAnchor.constraint(equalTo: field.bottomAnchor, constant: 5)
        ])
    }
    
    override func configure(from patient: Patient) {
        field.labelText = "Patient.\(attribute ?? "")".localized
        if let value = patient.value(forKey: attribute) {
            field.text = String(describing: value)
        } else {
            field.text = nil
        }
        switch attributeType {
        case .string:
            field.textField.keyboardType = .default
        case .number:
            field.textField.keyboardType = .numberPad
        case .object:
            break
        }
        field.textField.returnKeyType = .next
    }

    func addAlertLabelTapRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(alertPressed))
        field.alertLabel.addGestureRecognizer(recognizer)
        field.alertLabel.isUserInteractionEnabled = true
    }
    
    @objc private func alertPressed() {
        delegate?.attributeTableViewCellDidPressAlert?(self)
    }
    
    override func becomeFirstResponder() -> Bool {
        return field.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        return field.resignFirstResponder()
    }

    // MARK: - UITableViewCell

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        field.textField.isUserInteractionEnabled = editing
        field.textField.rightViewMode = editing ? .always : .never
    }
    
    // MARK: - UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if attributeType == .object {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { [weak self] (timer) in
                guard let self = self else { return }
                self.delegate?.attributeTableViewCellDidSelect?(self)
            })
            return false
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        layer.zPosition = 0
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        layer.zPosition = -1
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.attributeTableViewCellDidReturn?(self)
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                self.delegate?.attributeTableViewCell?(self, didChange: text)
            }
        }
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        timer?.invalidate()
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                self.delegate?.attributeTableViewCell?(self, didChange: "")
            }
        }
        return true
    }
}
