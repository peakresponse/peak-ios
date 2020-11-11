//
//  IconButton.swift
//  Triage
//
//  Created by Francis Li on 10/8/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class IconButton: FormButton {
    weak var iconBackgroundView: RoundImageView!

    override var isSelected: Bool {
        didSet { configure() }
    }

    override func commonInit() {
        super.commonInit()

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
        button.setNeedsLayout()

        button.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        button.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchDragExit, .touchUpOutside, .touchCancel])
    }

    func configure() {
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
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
