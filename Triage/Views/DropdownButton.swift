//
//  DropdownButton.swift
//  Triage
//
//  Created by Francis Li on 3/22/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class DropdownButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        if let backgroundColor = backgroundColor {
            setBackgroundImage(UIImage.resizableImage(withColor: backgroundColor, cornerRadius: 0), for: .normal)
            setBackgroundImage(UIImage.resizableImage(withColor: backgroundColor.colorWithBrightnessMultiplier(multiplier: 0.4), cornerRadius: 0), for: .highlighted)
            setBackgroundImage(UIImage.resizableImage(withColor: backgroundColor.colorWithBrightnessMultiplier(multiplier: 0.4), cornerRadius: 0), for: [.selected, .highlighted])
        }
        setImage(UIImage(named: "ChevronDown"), for: .normal)
        setImage(UIImage(named: "ChevronUp"), for: .selected)
        setImage(UIImage(named: "ChevronUp"), for: [.selected, .highlighted])
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        var titleRect = super.titleRect(forContentRect: contentRect)
        var imageRect = super.imageRect(forContentRect: contentRect)
        imageRect.size.width /= 2
        imageRect.size.height /= 2
        titleRect.origin.x = floor((contentRect.width - titleRect.width - imageRect.width - 4) / 2)
        titleRect.origin.y = floor((contentRect.height - titleRect.height) / 2)
        return titleRect
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let titleRect = super.titleRect(forContentRect: contentRect)
        var imageRect = super.imageRect(forContentRect: contentRect)
        imageRect.size.width /= 2
        imageRect.size.height /= 2
        imageRect.origin.x = floor((contentRect.width - titleRect.width - imageRect.width - 4) / 2) + titleRect.width + 4
        imageRect.origin.y = floor((contentRect.height - imageRect.height) / 2)
        return imageRect
    }
}
