//
//  SortBar.swift
//  Triage
//
//  Created by Francis Li on 8/8/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@objc protocol SortBarDelegate {
    @objc optional func sortBar(_ sortBar: SortBar, willShow selectorView: SelectorView)
    @objc optional func sortBar(_ sortBar: SortBar, selectorView: SelectorView, didSelectButtonAtIndex index: Int)
}

@IBDesignable
class SortBar: UIView, DropdownButtonDelegate {
    let label = UILabel()
    let dropdownButton = DropdownButton()

    weak var delegate: SortBarDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copySBold
        label.textColor = .lowPriorityGrey
        label.text = "SortBar.sortBy".localized
        label.sizeToFit()
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 32)
        ])
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        dropdownButton.delegate = self
        dropdownButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dropdownButton)
        NSLayoutConstraint.activate([
            dropdownButton.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            dropdownButton.leftAnchor.constraint(equalTo: label.rightAnchor, constant: 15),
            dropdownButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -22),
            dropdownButton.heightAnchor.constraint(equalToConstant: 40),
            bottomAnchor.constraint(equalTo: dropdownButton.bottomAnchor, constant: 5)
        ])
    }

    // MARK: - DropdownButtonDelegate
    
    func dropdownWillAppear(_ button: DropdownButton) -> UIView? {
        return superview
    }

    func dropdown(_ button: DropdownButton, willShow selectorView: SelectorView) {
        delegate?.sortBar?(self, willShow: selectorView)
    }

    func dropdown(_ button: DropdownButton, selectorView: SelectorView, didSelectButtonAtIndex index: Int) {
        delegate?.sortBar?(self, selectorView: selectorView, didSelectButtonAtIndex: index)
    }
}
