//
//  HorizontalRuleView.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class HorizontalRuleView: UIView {
    @IBInspectable var lineColor: UIColor = UIColor.black
    
    override func awakeFromNib() {
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        let size = frame.size
        let scale = UIScreen.main.scale
        let strokeWidth = 1 / scale
        let offset = 0.5 - (Int(scale) % 2 == 0 ? 1 / (scale * 2) : 0)
        let context = UIGraphicsGetCurrentContext()!
        context.clear(rect)
        context.setLineWidth(strokeWidth)
        context.setStrokeColor(lineColor.cgColor)
        context.beginPath()
        context.move(to: CGPoint(x: 0, y: size.height - offset))
        context.addLine(to: CGPoint(x: size.width, y: size.height - offset))
        context.strokePath()
    }
}
