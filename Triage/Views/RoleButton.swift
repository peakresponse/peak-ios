//
//  RoleButton.swift
//  Triage
//
//  Created by Francis Li on 10/8/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class RoleButton: FormButton {
    weak var iconBackgroundView: RoundImageView!

    override var isSelected: Bool {
        didSet { configure() }
    }
    var isMGS: Bool = false {
        didSet { configure() }
    }
    var role: ResponderRole? {
        didSet { configure() }
    }

    override var font: UIFont {
        switch size {
        case .xxsmall:
            return .copyXSBold
        case .xsmall:
            return .copyXSBold
        case .small:
            return .copySBold
        case .medium:
            return .copyMBold
        default:
            return .copyLBold
        }
    }

    override func commonInit() {
        super.commonInit()

        button.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        button.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchDragExit, .touchUpOutside, .touchCancel])

        let iconBackgroundView = RoundImageView()
        iconBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        iconBackgroundView.imageView.contentMode = .center
        button.addSubview(iconBackgroundView)
        NSLayoutConstraint.activate([
            iconBackgroundView.topAnchor.constraint(equalTo: button.topAnchor, constant: 2),
            iconBackgroundView.leftAnchor.constraint(equalTo: button.leftAnchor, constant: 2),
            iconBackgroundView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -2),
            iconBackgroundView.widthAnchor.constraint(equalTo: iconBackgroundView.heightAnchor)
        ])
        self.iconBackgroundView = iconBackgroundView
    }

    private func configure() {
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        if isMGS {
            highlightedButtonColor = .peakBlue
            buttonImage = UIImage(named: "Star")?.withRenderingMode(.alwaysTemplate)
            buttonLabel = "Responder.role.MGS".localized
            button.setTitleColor(.peakBlue, for: .normal)
            button.setTitleColor(.white, for: .highlighted)
            button.setTitleColor(.white, for: .selected)
            button.setTitleColor(.white, for: [.highlighted, .selected])
            iconBackgroundView.image = buttonImage
            iconBackgroundView.tintColor = isSelected ? .peakBlue : .white
            iconBackgroundView.backgroundColor = isSelected ? .white : .peakBlue
        } else if let role = role {
            highlightedButtonColor = role.color
            buttonImage = role.image.withRenderingMode(.alwaysTemplate)
            buttonLabel = role.description
            button.setTitleColor(role.color, for: .normal)
            button.setTitleColor(.white, for: .highlighted)
            button.setTitleColor(.white, for: .selected)
            button.setTitleColor(.white, for: [.highlighted, .selected])
            iconBackgroundView.image = buttonImage
            iconBackgroundView.tintColor = isSelected ? role.color : .white
            iconBackgroundView.backgroundColor = isSelected ? .white : role.color
        } else {
            buttonLabel = "Button.assignRole".localized
        }
    }

    override func updateButtonBackgroundImage(color: UIColor, state: UIControl.State) {
        switch state {
        case .normal:
            break
        case .highlighted:
            button.setBackgroundImage(UIImage.resizableImage(withColor: color, cornerRadius: height / 2), for: state)
            button.setBackgroundImage(UIImage.resizableImage(withColor: color, cornerRadius: height / 2), for: .selected)
            button.setBackgroundImage(UIImage.resizableImage(withColor: color.colorWithBrightnessMultiplier(multiplier: 0.4),
                                                             cornerRadius: height / 2), for: [.highlighted, .selected])
        default:
            break
        }
    }

    @objc func buttonPressed() {
        iconBackgroundView.backgroundColor = .white
        iconBackgroundView.tintColor = isSelected ?
            highlightedButtonColor.colorWithBrightnessMultiplier(multiplier: 0.4) :
            highlightedButtonColor
    }

    @objc func buttonReleased() {
        iconBackgroundView.backgroundColor = isSelected ? .white : highlightedButtonColor
        iconBackgroundView.tintColor = isSelected ? highlightedButtonColor : .white
    }
}
