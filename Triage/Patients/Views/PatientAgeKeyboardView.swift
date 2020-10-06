//
//  PatientAgeKeyboardView.swift
//  Triage
//
//  Created by Francis Li on 10/4/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@objc protocol PatientAgeKeyboardViewDelegate {
    @objc optional func patientAgeKeyboardView(_ view: PatientAgeKeyboardView, didSelect age: Int, units: String)
}

class PatientAgeKeyboardView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    weak var textField: UITextField!
    weak var pickerView: UIPickerView!
    weak var delegate: PatientAgeKeyboardViewDelegate?

    convenience init(textField: UITextField, age: Int?, units: String?) {
        self.init(frame: CGRect(x: 0, y: 0, width: 0, height: 216))
        self.textField = textField
        var ageString = ""
        if let row = age {
            ageString = "\(row)"
            pickerView.selectRow(row, inComponent: 0, animated: false)
        }
        if let units = units, let ageUnits = PatientAgeUnits(rawValue: units),
           let row = PatientAgeUnits.allCases.firstIndex(where: {$0 == ageUnits}) {
            ageString = "\(ageString) \(ageUnits.abbrDescription)"
            pickerView.selectRow(row, inComponent: 1, animated: false)
        }
        textField.text = ageString
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
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return 121
        case 1:
            return PatientAgeUnits.allCases.count
        default:
            return 0
        }
    }

    // MARK: - UIPickerViewDelegate

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            if row > 0 {
                return "\(row)"
            }
            return ""
        case 1:
            return PatientAgeUnits.allCases[row].description
        default:
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var age = 0
        var units = PatientAgeUnits.years.rawValue
        switch component {
        case 0:
            age = row
            units = PatientAgeUnits.allCases[pickerView.selectedRow(inComponent: 1)].rawValue
        case 1:
            age = pickerView.selectedRow(inComponent: 0)
            units = PatientAgeUnits.allCases[row].rawValue
        default:
            break
        }
        delegate?.patientAgeKeyboardView?(self,
                                          didSelect: age,
                                          units: units)
        if age > 0 {
            textField.text = "\(age) \("Patient.ageUnits.abbr.\(units)".localized)"
        } else {
            textField.text = nil
        }
    }
}
