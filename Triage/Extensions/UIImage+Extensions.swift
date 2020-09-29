//
//  UIImage+Extensions.swift
//  Triage
//
//  Created by Francis Li on 3/16/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

extension UIImage {
    static func resizableImage(withColor color: UIColor, cornerRadius: CGFloat,
                               borderColor: UIColor? = nil, borderWidth: CGFloat? = nil, corners: UIRectCorner = .allCorners) -> UIImage {
        let size = 2 * cornerRadius + 1
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()!
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size),
                                byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        context.addPath(path.cgPath)
        context.setFillColor(color.cgColor)
        context.fillPath()
        if let borderColor = borderColor, let borderWidth = borderWidth {
            // strokePath strokes centered, so clip and double width to stroke inner
            context.addPath(path.cgPath)
            context.clip()
            context.addPath(path.cgPath)
            context.setStrokeColor(borderColor.cgColor)
            context.setLineWidth(borderWidth * 2)
            context.strokePath()
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image.resizableImage(withCapInsets: UIEdgeInsets(top: cornerRadius, left: cornerRadius,
                                                                bottom: cornerRadius, right: cornerRadius))
    }
}
