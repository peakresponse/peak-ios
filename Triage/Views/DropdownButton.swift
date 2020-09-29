//
//  DropdownButton.swift
//  Triage
//
//  Created by Francis Li on 3/22/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@objc protocol DropdownButtonDelegate {
    @objc optional func dropdownWillAppear(_ button: DropdownButton) -> UIView?
    @objc optional func dropdown(_ button: DropdownButton, willShow selectorView: SelectorView)
    @objc optional func dropdown(_ button: DropdownButton, selectorView: SelectorView, didSelectButtonAtIndex index: Int)
}

@IBDesignable
class DropdownButton: SelectorButton, SelectorViewDelegate {
    private weak var selectorView: SelectorView?
    @IBOutlet weak var delegate: DropdownButtonDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        titleLabel?.font = .copySBold
        setTitleColor(.mainGrey, for: .normal)
        setBackgroundImage(UIImage.resizableImage(withColor: .white, cornerRadius: 2),
                           for: .normal)
        setBackgroundImage(UIImage.resizableImage(withColor: UIColor.white.colorWithBrightnessMultiplier(multiplier: 0.4),
                                                  cornerRadius: 2),
                           for: .highlighted)
        setBackgroundImage(UIImage.resizableImage(withColor: UIColor.white.colorWithBrightnessMultiplier(multiplier: 0.4),
                                                  cornerRadius: 2),
                           for: [.selected, .highlighted])
        setImage(UIImage(named: "ChevronDown"), for: .normal)
        setImage(UIImage(named: "ChevronUp"), for: .selected)
        setImage(UIImage(named: "ChevronUp"), for: [.selected, .highlighted])
        addShadow(withOffset: CGSize(width: 0, height: 1), radius: 3, color: .black, opacity: 0.1)
        addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }

    @objc private func buttonPressed() {
        if let selectorView = selectorView {
            // toggle off dropdown without any selection
            selectorView.removeFromSuperview()
            self.selectorView = nil
        } else {
            // create and show dropdown
            guard let view = delegate?.dropdownWillAppear?(self) ?? superview else { return }
            let selectorView = SelectorView()
            selectorView.translatesAutoresizingMaskIntoConstraints = false
            selectorView.delegate = self
            delegate?.dropdown?(self, willShow: selectorView)
            view.addSubview(selectorView)
            NSLayoutConstraint.activate([
                selectorView.topAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                selectorView.leftAnchor.constraint(equalTo: leftAnchor),
                selectorView.rightAnchor.constraint(equalTo: rightAnchor)
            ])
            self.selectorView = selectorView
        }
        isSelected = selectorView != nil
    }

    // MARK: - SelectorViewDelegate

    func selectorView(_ selectorView: SelectorView, didSelectButtonAtIndex index: Int) {
        delegate?.dropdown?(self, selectorView: selectorView, didSelectButtonAtIndex: index)
        selectorView.removeFromSuperview()
        isSelected = false
    }
}
