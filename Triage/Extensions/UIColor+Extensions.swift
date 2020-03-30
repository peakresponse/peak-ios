//
//  UIColor+Extensions.swift
//  Triage
//
//  Created by Francis Li on 3/10/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

extension UIColor {
    static var immediateRed: UIColor {
        return UIColor(r: 237, g: 117, b: 66)
    }

    static var immediateRedLightened: UIColor {
        return UIColor(r: 238, g: 169, b: 139)
    }
    
    static var delayedYellow: UIColor {
        return UIColor(r: 243, g: 236, b: 66)
    }

    static var delayedYellowLightened: UIColor {
        return UIColor(r: 251, g: 248, b: 189)
    }
    
    static var minimalGreen: UIColor {
        return UIColor(r: 66, g: 237, b: 114)
    }

    static var minimalGreenLightened: UIColor {
        return UIColor(r: 197, g: 249, b: 211)
    }
    
    static var expectantGray: UIColor {
        return UIColor(r: 186, g: 191, b: 187)
    }

    static var expectantGrayLightened: UIColor {
        return UIColor(r: 214, g: 215, b: 214)
    }
    
    static var deadBlack: UIColor {
        return UIColor(r: 71, g: 71, b: 71)
    }

    static var deadBlackLightened: UIColor {
        return UIColor(r: 139, g: 139, b: 138)
    }

    static var backgroundBlueGray: UIColor {
        return UIColor(r: 229, g: 236, b: 239)
    }

    static var bottomBlueGray: UIColor {
        return UIColor(r: 245, g: 247, b: 249)
    }
    
    static var natBlue: UIColor {
        return UIColor(r: 70, g: 165, b: 219)
    }

    static var natBlueLightened: UIColor {
        return UIColor(r: 208, g: 233, b: 247)
    }
    
    static var gray2: UIColor {
        return UIColor(r: 79, g: 79, b: 79)
    }
    
    static var gray4: UIColor {
        return UIColor(r: 189, g: 189, b: 189)
    }

    convenience public init(r: Int, g: Int, b: Int) {
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1.0)
    }

    func colorWithBrightnessMultiplier(multiplier: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: b * multiplier, alpha: a)
    }
}
