//
//  UIView+Extensions.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

extension UIView {

    func addShadow(withOffset offset: CGSize, radius: CGFloat, color: UIColor, opacity: Float) {
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
    }

    func removeShadow() {
        layer.shadowOffset = .zero
        layer.shadowRadius = 0
        layer.shadowColor = nil
        layer.shadowOpacity = 0
    }
}
