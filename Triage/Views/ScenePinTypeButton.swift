//
//  ScenePinTypeButton.swift
//  Triage
//
//  Created by Francis Li on 10/8/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class ScenePinTypeButton: IconButton {
    var pinType: ScenePinType? {
        didSet { configure() }
    }

    override func configure() {
        super.configure()
        guard let pinType = pinType else { return }
        buttonColor = .white
        highlightedButtonColor = pinType.color
        selectedButtonColor = highlightedButtonColor
        selectedHighlightedButtonColor = selectedButtonColor.colorWithBrightnessMultiplier(multiplier: 0.4)
        buttonLabel = pinType.description
        button.setTitleColor(pinType.color, for: .normal)
        button.setTitleColor(.white, for: .highlighted)
        button.setTitleColor(.white, for: .selected)
        button.setTitleColor(.white, for: [.highlighted, .selected])
        button.titleLabel?.font = .copyXSBold
        button.titleLabel?.numberOfLines = 0
        iconBackgroundView.image = pinType.image.withRenderingMode(.alwaysTemplate)
        iconBackgroundView.isHidden = false
        iconBackgroundView.tintColor = isSelected ? pinType.color : .white
        iconBackgroundView.backgroundColor = isSelected ? .white : pinType.color
    }
}
