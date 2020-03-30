//
//  PriorityTabView.swift
//  Triage
//
//  Created by Francis Li on 3/16/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@objc protocol PriorityTabViewDelegate {
    func priorityTabViewDidChange(_ priorityTabView: PriorityTabView)
}

@IBDesignable
class PriorityTabView: UIView {
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!
    
    weak var delegate: PriorityTabViewDelegate?

    @IBInspectable var isOpen: Bool = false {
        didSet { setPriority() }
    }
    @IBInspectable var priorityValue: Int = 0 {
        didSet { setPriority() }
    }
    var priority: Priority {
        return Priority(rawValue: priorityValue) ?? .immediate
    }
    var count: Int = 0 {
        didSet { setCount() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        loadNib()
        setPriority()
    }

    private func setPriority() {
        let bgColor = PRIORITY_COLORS[priority.rawValue]
        let corners = isOpen ? [UIRectCorner.topLeft, UIRectCorner.topRight] : UIRectCorner.allCorners
        button.setBackgroundImage(UIImage.resizableImage(withColor: bgColor, cornerRadius: 3, corners: corners), for: .normal)
        button.setBackgroundImage(UIImage.resizableImage(withColor: bgColor.colorWithBrightnessMultiplier(multiplier: 0.4), cornerRadius: 3, corners: corners), for: .highlighted)
        button.addShadow(withOffset: CGSize(width: 1, height: 2), radius: 2, color: UIColor.black, opacity: 0.1)
        button.addTarget(self, action: #selector(buttonHighlighted(_:)), for: [.touchDown])
        button.addTarget(self, action: #selector(buttonUnhighlighted(_:)), for: [.touchDragExit, .touchUpInside, .touchUpOutside, .touchCancel])
        button.isUserInteractionEnabled = !isOpen

        titleLabel.text = priority.description;
        titleLabel.textColor = PRIORITY_LABEL_COLORS[priority.rawValue]
        titleLabel.highlightedTextColor = .white
        countLabel.textColor = PRIORITY_LABEL_COLORS[priority.rawValue]
        countLabel.highlightedTextColor = .white
        countLabel.isHidden = true

        arrowImageView.tintColor = PRIORITY_LABEL_COLORS[priority.rawValue]
        arrowImageView.isHidden = isOpen

        setCount()
    }

    private func setCount() {
        countLabel.isHidden = false
        countLabel.text = " - \(count) p"
    }

    @objc func buttonHighlighted(_ sender: Any) {
        titleLabel.isHighlighted = true
        countLabel.isHighlighted = true
    }
    
    @objc func buttonUnhighlighted(_ sender: Any) {
        titleLabel.isHighlighted = false
        countLabel.isHighlighted = false
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        if !isOpen {
            isOpen = true
            setPriority()
            delegate?.priorityTabViewDidChange(self)
        }
    }
}
