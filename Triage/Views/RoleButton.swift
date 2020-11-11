//
//  RoleButton.swift
//  Triage
//
//  Created by Francis Li on 10/8/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class RoleButton: IconButton {
    var isMGS: Bool = false {
        didSet {
            if isMGS {
                isOther = false
                role = nil
                configure()
            }
        }
    }
    var isOther: Bool = false {
        didSet {
            if isOther {
                isMGS = false
                role = nil
                configure()
            }
        }
    }
    @IBInspectable var Role: String? {
        get { role?.rawValue }
        set { role = ResponderRole(rawValue: newValue ?? "") }
    }
    var role: ResponderRole? {
        didSet {
            if role != nil {
                isMGS = false
                isOther = false
                configure()
            }
        }
    }

    override func configure() {
        super.configure()
        if !isMGS && role == nil {
            style = .lowPriority
            iconBackgroundView.isHidden = true
            buttonImage = nil
            iconBackgroundView.image = nil
            buttonLabel = "Button.assignRole".localized
            buttonColor = .greyPeakBlue
            highlightedButtonColor = .darkPeakBlue
            button.titleLabel?.font = .copySBold
            button.titleLabel?.numberOfLines = 1
            button.titleEdgeInsets = .zero
            updateButtonStyles()
        } else {
            style = .priority
            buttonColor = .clear
            highlightedButtonColor = role?.color ?? .peakBlue
            selectedButtonColor = highlightedButtonColor
            selectedHighlightedButtonColor = selectedButtonColor.colorWithBrightnessMultiplier(multiplier: 0.4)
            buttonImage = role?.image.withRenderingMode(.alwaysTemplate) ??
                UIImage(named: "Star", in: Bundle(for: type(of: self)), with: nil)?.withRenderingMode(.alwaysTemplate)
            buttonLabel = role?.description ?? "Responder.role.MGS".localized
            button.setTitleColor(role?.color ?? .peakBlue, for: .normal)
            button.setTitleColor(.white, for: .highlighted)
            button.setTitleColor(.white, for: .selected)
            button.setTitleColor(.white, for: [.highlighted, .selected])
            button.titleLabel?.font = .copyXSBold
            button.titleLabel?.numberOfLines = 0
            iconBackgroundView.image = buttonImage
            iconBackgroundView.isHidden = false
            iconBackgroundView.tintColor = isSelected ? role?.color ?? .peakBlue : .white
            iconBackgroundView.backgroundColor = isSelected ? .white : role?.color ?? .peakBlue
        }
    }

    override func updateButtonBackgroundImage(color: UIColor, state: UIControl.State) {
        if role == nil && !isMGS {
            button.setBackgroundImage(UIImage.resizableImage(withColor: .bgBackground, cornerRadius: height / 2,
                                                             borderColor: color, borderWidth: size == .xxsmall ? 1 : 3), for: state)
            return
        }
        super.updateButtonBackgroundImage(color: color, state: state)
    }
}
