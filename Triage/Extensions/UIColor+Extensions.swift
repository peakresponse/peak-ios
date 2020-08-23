//
//  UIColor+Extensions.swift
//  Triage
//
//  Created by Francis Li on 3/10/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

extension UIColor {
    /// Helper for retrieving colors from the Assets xcassets bundle- providing an explicit Bundle
    /// reference ensures this works in other contexts- including Interface Builder IBDesignable execution
    private static func named(_ name: String) -> UIColor {
        return UIColor(named: name, in: Bundle(for: AppDelegate.self), compatibleWith: nil)!
    }
    
    static var immediateRed: UIColor {
        return UIColor.named("ImmediateRed")
    }

    static var immediateRedLightened: UIColor {
        return UIColor.named("LightImmediateRed")
    }
    
    static var delayedYellow: UIColor {
        return UIColor.named("DelayedYellow")
    }

    static var delayedYellowLightened: UIColor {
        return UIColor.named("LightDelayedYellow")
    }
    
    static var minimalGreen: UIColor {
        return UIColor.named("MinimalGreen")
    }

    static var minimalGreenLightened: UIColor {
        return UIColor.named("LightMinimalGreen")
    }
    
    static var expectantGray: UIColor {
        return UIColor.named("ExpectGrey")
    }

    static var expectantGrayLightened: UIColor {
        return UIColor.named("LightExpectGrey")
    }
    
    static var deadBlack: UIColor {
        return UIColor.named("DeadBlack")
    }

    static var deadBlackLightened: UIColor {
        return UIColor.named("LightDeadBlack")
    }

    static var peakBlue: UIColor {
        return UIColor.named("PeakBlue")
    }
    
    static var lightPeakBlue: UIColor {
        return UIColor.named("LightPeakBlue")
    }
    
    static var middlePeakBlue: UIColor {
        return UIColor.named("MiddlePeakBlue")
    }
    
    static var darkPeakBlue: UIColor {
        return UIColor.named("DarkPeakBlue")
    }
    
    static var greyPeakBlue: UIColor {
        return UIColor.named("GreyPeakBlue")
    }

    static var bgBackground: UIColor {
        return UIColor.named("BgBackground")
    }
    
    static var orangeAccent: UIColor {
        return UIColor.named("OrangeAccent")
    }
    
    static var mainGrey: UIColor {
        return UIColor.named("MainGrey")
    }
    
    static var lowPriorityGrey: UIColor {
        return UIColor.named("LowPriorityGrey")
    }

    /// deprecated legacy colors -------------------
    
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
    
    static var gray3: UIColor {
        return UIColor(r: 130, g: 130, b: 130)
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
