//
//  TextField.swift
//  Triage
//
//  Created by Francis Li on 3/10/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class TextField: UITextField {
    @IBInspectable var padding: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: padding.width, dy: padding.height)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }

    private func commonInit() {
        backgroundColor = .white
        textColor = .mainGrey
        font = .copyLBold
        addShadow(withOffset: CGSize(width: 0, height: 6), radius: 10, color: .black, opacity: 0.15)
    }
}
