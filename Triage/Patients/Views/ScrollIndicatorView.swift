//
//  ScrollIndicatorView.swift
//  Triage
//
//  Created by Francis Li on 10/4/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class ScrollIndicatorView: UIView, UIScrollViewDelegate {
    weak var label: UILabel!
    weak var imageView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isUserInteractionEnabled = false

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.bgBackground.withAlphaComponent(0).cgColor, UIColor.bgBackground.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 22 / frame.height)
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = bounds
        layer.insertSublayer(gradientLayer, at: 0)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copyXSRegular
        label.text = "ScrollIndicatorView.label".localized
        label.textColor = .lowPriorityGrey
        label.textAlignment = .center
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 22),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -22)
        ])
        self.label = label

        let imageView = UIImageView(image: UIImage(named: "Scroll"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 5),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 0)
        ])
        self.imageView = imageView
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for layer in layer.sublayers ?? [] {
            if let layer = layer as? CAGradientLayer {
                layer.endPoint = CGPoint(x: 0.5, y: 22 / frame.height)
                layer.frame = bounds
            }
        }
    }
}
