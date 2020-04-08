//
//  SelectorView.swift
//  Triage
//
//  Created by Francis Li on 3/22/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@objc protocol SelectorViewDelegate {
    @objc optional func selectorView(_ view: SelectorView, didSelectButtonAtIndex index: Int)
}

class SelectorView: UIStackView {
    private weak var heightConstraint: NSLayoutConstraint!
    weak var delegate: SelectorViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false

        let heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([heightConstraint])
        self.heightConstraint = heightConstraint

        axis = .vertical
        distribution = .fillEqually
        alignment = .fill
    }
    
    func addButton(title: String) {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .natBlueLightened
        button.setBackgroundImage(UIImage.resizableImage(withColor: .natBlue, cornerRadius: 0), for: .highlighted)
        button.titleLabel?.font = UIFont(name: "NunitoSans-SemiBold", size: 12) ?? UIFont.systemFont(ofSize: 12)
        button.setTitleColor(.gray2, for: .normal)
        button.setTitleColor(.white, for: .highlighted)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        addArrangedSubview(button)
        heightConstraint.constant = CGFloat(arrangedSubviews.count) * 28
    }

    @objc func buttonPressed(_ button: UIButton) {
        if let index = arrangedSubviews.firstIndex(of: button) {
            delegate?.selectorView?(self, didSelectButtonAtIndex: index)
        }
        removeFromSuperview()
    }
}
