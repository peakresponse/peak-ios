//
//  PinField.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class PinTextField: UITextField {
    var inset = CGSize.zero

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: inset.width, dy: inset.height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}

@objc protocol PinFieldDelegate {
    @objc optional func pinField(_ field: PinField, didChange pin: String)
    @objc optional func pinFieldDidBeginEditing(_ field: PinField)
    @objc optional func pinFieldDidEndEditing(_ field: PinField)
}

@IBDesignable
class PinField: UIView, UITextFieldDelegate {
    @IBOutlet weak var textField: PinTextField!
    @IBOutlet weak var stackView: UIStackView!
    @IBInspectable var length = 6

    weak var delegate: PinFieldDelegate?
    
    var font: UIFont? {
        get { return textField.font }
        set { textField.font = newValue; updateAttributes() }
    }

    var text: String? {
        get { return textField.text }
        set { textField.text = newValue }
    }

    var kern: CGFloat = 0
    
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
        for view in stackView.arrangedSubviews {
            view.addShadow(withOffset: CGSize(width: 0, height: 4), radius: 4, color: UIColor.black, opacity: 0.1)
        }
        updateAttributes()
    }

    private func updateAttributes() {
        let size = ("5" as NSString).size(withAttributes: [
            .font: textField.font as Any
        ])
        kern = size.width / 4
        textField.inset = CGSize(width: kern, height: kern)
        textField.defaultTextAttributes = [
            .font: textField.font as Any,
            .kern: 3 * kern
        ]
        stackView.spacing = CGFloat(kern)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = ("555555" as NSString).size(withAttributes: [
            .font: textField.font as Any
        ])
        size.width = round(size.width + kern * 17)
        size.height = round(size.height)
        return size
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
