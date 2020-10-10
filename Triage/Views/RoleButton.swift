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
    @IBInspectable var Role: String? {
        get { role?.rawValue }
        set { role = ResponderRole(rawValue: newValue ?? "") }
    }
    var role: ResponderRole? {
        didSet { configure() }
    }

    override func commonInit() {
        super.commonInit()

        button.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        button.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchDragExit, .touchUpOutside, .touchCancel])

        let iconBackgroundView = RoundImageView()
        iconBackgroundView.isUserInteractionEnabled = false
        iconBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        iconBackgroundView.imageView.contentMode = .center
        iconBackgroundView.isHidden = true
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
            buttonImage = UIImage(named: "Star", in: Bundle(for: type(of: self)), with: nil)?.withRenderingMode(.alwaysTemplate)
            buttonLabel = "Responder.role.MGS".localized
            button.setTitleColor(.peakBlue, for: .normal)
            button.setTitleColor(.white, for: .highlighted)
            button.setTitleColor(.white, for: .selected)
            button.setTitleColor(.white, for: [.highlighted, .selected])
            button.titleLabel?.font = .copyXSBold
            button.titleLabel?.numberOfLines = 0
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -22)
            iconBackgroundView.image = buttonImage
            iconBackgroundView.isHidden = false
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
            button.titleLabel?.font = .copyXSBold
            button.titleLabel?.numberOfLines = 0
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -22)
            iconBackgroundView.image = buttonImage
            iconBackgroundView.isHidden = false
            iconBackgroundView.tintColor = isSelected ? role.color : .white
            iconBackgroundView.backgroundColor = isSelected ? .white : role.color
        } else {
            iconBackgroundView.isHidden = true
            buttonImage = nil
            buttonLabel = "Button.assignRole".localized
            buttonColor = .greyPeakBlue
            highlightedButtonColor = UIColor.greyPeakBlue.colorWithBrightnessMultiplier(multiplier: 0.4)
            button.titleLabel?.font = .copySBold
            button.titleLabel?.numberOfLines = 1
            button.titleEdgeInsets = .zero
            updateButtonStyles()
        }
    }

    override func updateButtonBackgroundImage(color: UIColor, state: UIControl.State) {
        if role == nil && !isMGS {
            button.setBackgroundImage(UIImage.resizableImage(withColor: .bgBackground, cornerRadius: height / 2,
                                                             borderColor: color, borderWidth: size == .xxsmall ? 1 : 3), for: state)
            return
        }
        switch state {
        case .highlighted:
            button.setBackgroundImage(nil, for: .normal)
            button.setBackgroundImage(UIImage.resizableImage(withColor: color, cornerRadius: height / 2), for: .highlighted)
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
