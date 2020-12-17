//
//  SearchBar.swift
//  Triage
//
//  Created by Francis Li on 8/7/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

enum SearchBarStyle: String {
    case navigation, embedded
}

@IBDesignable
class SearchBar: UISearchBar, UITextFieldDelegate {
    private var clearImage: UIImage!
    private var searchImage: UIImage!
    private var searchImageButton: UIButton!

    private var _textField: UITextField!
    var textField: UITextField! {
        if #available(iOS 13.0, *) {
            return searchTextField
        } else {
            if _textField == nil {
                _textField = UITextField()
                _textField.placeholder = placeholder
                addSubview(_textField)
                if let searchTextField = subviews[0].subviews.first(where: {$0.isKind(of: UITextField.self)}) as? UITextField {
                    searchTextField.alpha = 0
                    NSLayoutConstraint.activate([
                        _textField.heightAnchor.constraint(equalTo: searchTextField.heightAnchor)
                    ])
                    _textField.delegate = self
                }
            }
            return _textField
        }
    }

    override var text: String? {
        get {
            if #available(iOS 13.0, *) {
                return super.text
            } else {
                return textField.text
            }
        }
        set {
            if #available(iOS 13.0, *) {
                super.text = newValue
            } else {
                textField.text = newValue
            }
        }
    }

    var style: SearchBarStyle = .navigation {
        didSet { updateStyle() }
    }
    @IBInspectable var Style: String {
        get { return style.rawValue }
        set { style = SearchBarStyle(rawValue: newValue) ?? .navigation }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func becomeFirstResponder() -> Bool {
        if #available(iOS 13.0, *) {
            return super.becomeFirstResponder()
        } else {
            return textField.becomeFirstResponder()
        }
    }

    override func resignFirstResponder() -> Bool {
        if #available(iOS 13.0, *) {
            return super.resignFirstResponder()
        } else {
            return textField.resignFirstResponder()
        }
    }

    private func commonInit() {
        // hack to get rid of default bottom border
        // https://stackoverflow.com/questions/7620564/customize-uisearchbar-trying-to-get-rid-of-the-1px-black-line-underneath-the-se
        layer.borderWidth = 1
        // adjust padding/insets
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            textField.rightAnchor.constraint(equalTo: rightAnchor, constant: -22)
        ])
        // remove default search icon, add padding
        var padding = 12
        if #available(iOS 13.0, *) {
            padding = 6
        }
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: 0))
        textField.leftViewMode = .always
        // default search placeholder text
        textField.placeholder = placeholder ?? "SearchBar.placeholder".localized
        // change clear icon
        clearImage = UIImage(named: "Clear", in: Bundle(for: type(of: self)), compatibleWith: nil)
        setImage(clearImage, for: .clear, state: .normal)
        setPositionAdjustment(UIOffset(horizontal: -10, vertical: 0), for: .clear)
        // add custom search icon on right
        searchImage = UIImage(named: "Search", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let button = UIButton(type: .custom)
        button.setImage(searchImage, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        button.addTarget(self, action: #selector(searchImageButtonPressed), for: .touchUpInside)
        addSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 20),
            button.heightAnchor.constraint(equalToConstant: 20),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.rightAnchor.constraint(equalTo: textField.rightAnchor, constant: -12)
        ])
        searchImageButton = button
        // style text field per design
        textField.font = .copySBold
        textField.textColor = .mainGrey
        textField.layer.cornerRadius = 10
        textField.addTarget(self, action: #selector(searchChanged(_:)), for: .editingChanged)
        textField.returnKeyType = .done
        // style per context
        updateStyle()
    }

    private func updateStyle() {
        switch style {
        case .navigation:
            barTintColor = .white
            layer.borderColor = UIColor.white.cgColor
            addShadow(withOffset: CGSize(width: 0, height: 6), radius: 20, color: .black, opacity: 0.1)
            textField.backgroundColor = .bgBackground
            textField.layer.borderWidth = 1
            textField.layer.borderColor = UIColor.middlePeakBlue.cgColor
            textField.removeShadow()
        case .embedded:
            barTintColor = .bgBackground
            layer.borderColor = UIColor.bgBackground.cgColor
            removeShadow()
            textField.backgroundColor = .white
            textField.layer.borderWidth = 0
            textField.addShadow(withOffset: CGSize(width: 0, height: 1), radius: 3, color: .black, opacity: 0.1)
        }
    }

    @objc private func searchChanged(_ sender: Any) {
        if #available(iOS 13.0, *) {
            searchImageButton.isHidden = !(text?.isEmpty ?? true)
        } else {
            if text?.isEmpty ?? true {
                searchImageButton.setImage(searchImage, for: .normal)
                searchImageButton.isUserInteractionEnabled = false
            } else {
                searchImageButton.setImage(clearImage, for: .normal)
                searchImageButton.isUserInteractionEnabled = true
            }
            delegate?.searchBar?(self, textDidChange: text ?? "")
        }
    }

    @objc private func searchImageButtonPressed() {
        text = nil
        delegate?.searchBar?(self, textDidChange: text ?? "")
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return delegate?.searchBarShouldBeginEditing?(self) ?? true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return delegate?.searchBarShouldEndEditing?(self) ?? true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.searchBarSearchButtonClicked?(self)
        return true
    }
}
