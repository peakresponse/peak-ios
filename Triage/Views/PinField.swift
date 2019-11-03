//
//  PinField.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class PinTextField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds
    }
}

@objc protocol PinFieldDelegate {
    @objc optional func pinField(_ field: PinField, didChange pin: String)
    @objc optional func pinFieldDidBeginEditing(_ field: PinField)
    @objc optional func pinFieldDidEndEditing(_ field: PinField)
}

@IBDesignable
class PinField: UIView, UITextFieldDelegate {
    @IBOutlet weak var textField: UITextField!
    @IBInspectable var length = 6

    weak var delegate: PinFieldDelegate?
    
    var font: UIFont? {
        get { return textField.font }
        set { textField.font = newValue }
    }

    var text: String? {
        get { return textField.text }
        set { textField.text = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        loadNib()
    }
    
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.pinFieldDidBeginEditing?(self)        
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.pinFieldDidEndEditing?(self)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
            let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
            if text.count <= length {
                DispatchQueue.main.async { [weak self] in
                    if let self = self {
                        self.delegate?.pinField?(self, didChange: text)
                    }
                }
                return true
            }
        }
        return false
    }
}
