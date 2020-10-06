//
//  PatientGenderKeyboardView.swift
//  Triage
//
//  Created by Francis Li on 10/4/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@objc protocol PatientGenderKeyboardViewDelegate {
    @objc optional func patientGenderKeyboardView(_ view: PatientGenderKeyboardView, didSelect gender: String?)
}

class PatientGenderKeyboardView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    weak var textField: UITextField!
    weak var pickerView: UIPickerView!
    weak var delegate: PatientGenderKeyboardViewDelegate?

    convenience init(textField: UITextField, value: String?) {
        self.init(frame: CGRect(x: 0, y: 0, width: 0, height: 216))
        self.textField = textField
        if let value = value, let gender = PatientGender(rawValue: value) {
            textField.text = gender.description
            if let row = PatientGender.allCases.firstIndex(of: gender) {
                pickerView.selectRow(row + 1, inComponent: 0, animated: false)
            }
        }
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
        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.delegate = self
        addSubview(pickerView)
        NSLayoutConstraint.activate([
            pickerView.topAnchor.constraint(equalTo: topAnchor),
            pickerView.leftAnchor.constraint(equalTo: leftAnchor),
            pickerView.rightAnchor.constraint(equalTo: rightAnchor),
            bottomAnchor.constraint(equalTo: pickerView.bottomAnchor)
        ])
        self.pickerView = pickerView
    }

    // MARK: - UIPickerViewDataSource

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return PatientGender.allCases.count + 1
    }

    // MARK: - UIPickerViewDelegate

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row > 0 {
            return PatientGender.allCases[row - 1].description
        }
        return ""
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        textField.text = row > 0 ? PatientGender.allCases[row - 1].description : nil
        delegate?.patientGenderKeyboardView?(self, didSelect: row > 0 ? PatientGender.allCases[row - 1].rawValue : nil)
    }
}
