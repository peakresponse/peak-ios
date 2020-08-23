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
class SearchBar: UISearchBar {
    private var searchImageView: UIImageView!

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

    private func commonInit() {
        /// hack to get rid of default bottom border: https://stackoverflow.com/questions/7620564/customize-uisearchbar-trying-to-get-rid-of-the-1px-black-line-underneath-the-se
        layer.borderWidth = 1
        /// adjust padding/insets
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchTextField.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchTextField.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            searchTextField.rightAnchor.constraint(equalTo: rightAnchor, constant: -22)
        ])
        /// remove default search icon, add padding
        searchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 0))
        /// change clear icon
        setImage(UIImage(named: "Clear", in: Bundle(for: type(of: self)), with: nil), for: .clear, state: .normal)
        setPositionAdjustment(UIOffset(horizontal: -10, vertical: 0), for: .clear)
        /// add custom search icon on right
        let imageView = UIImageView(image: UIImage(named: "Search", in: Bundle(for: type(of: self)), with: nil))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.rightAnchor.constraint(equalTo: searchTextField.rightAnchor, constant: -12)
        ])
        searchImageView = imageView
        /// style text field per design
        searchTextField.font = .copySBold
        searchTextField.textColor = .mainGrey
        searchTextField.layer.cornerRadius = 10
        searchTextField.addTarget(self, action: #selector(searchChanged(_:)), for: .editingChanged)
        searchTextField.returnKeyType = .done
        /// style per context
        updateStyle()
    }

    private func updateStyle() {
        switch style {
        case .navigation:
            barTintColor = .white
            layer.borderColor = UIColor.white.cgColor
            addShadow(withOffset: CGSize(width: 0, height: 6), radius: 20, color: .black, opacity: 0.1)
            searchTextField.backgroundColor = .bgBackground
            searchTextField.layer.borderWidth = 1
            searchTextField.layer.borderColor = UIColor.middlePeakBlue.cgColor
            searchTextField.removeShadow()
        case .embedded:
            barTintColor = .bgBackground
            layer.borderColor = UIColor.bgBackground.cgColor
            removeShadow()
            searchTextField.backgroundColor = .white
            searchTextField.layer.borderWidth = 0
            searchTextField.addShadow(withOffset: CGSize(width: 0, height: 1), radius: 3, color: .black, opacity: 0.1)
        }
    }
    
    @objc private func searchChanged(_ sender: Any) {
        searchImageView.isHidden = !(text?.isEmpty ?? true)
    }
}

