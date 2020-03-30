//
//  Button.swift
//  Triage
//
//  Created by Francis Li on 3/10/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class Button: UIButton {
    override var backgroundColor: UIColor? {
        didSet { updateButtonBackgrounds() }
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
        updateButtonBackgrounds()
        layer.cornerRadius = frame.height / 2
        addShadow(withOffset: CGSize(width: 0, height: 4), radius: 4, color: UIColor.black, opacity: 0.4)
    }
    
    private func updateButtonBackgrounds() {
        if let backgroundColor = backgroundColor {
            setBackgroundImage(UIImage.resizableImage(withColor: backgroundColor, cornerRadius: frame.height / 2), for: .normal)
            setBackgroundImage(UIImage.resizableImage(withColor: backgroundColor.colorWithBrightnessMultiplier(multiplier: 0.4), cornerRadius: frame.height / 2), for: .highlighted)
        }
    }
}
