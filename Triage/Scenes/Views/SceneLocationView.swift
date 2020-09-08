//
//  SceneLocationView.swift
//  Triage
//
//  Created by Francis Li on 9/3/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class SceneLocationView: UIView {
    @objc weak var gpsLabel: UILabel!
    @objc weak var cityLabel: UILabel!
    @objc weak var stateLabel: UILabel!
    @objc weak var zipLabel: UILabel!
    @objc weak var startLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear

        var prevLabel: UILabel!
        for attr in ["gpsLabel", "cityLabel", "stateLabel", "zipLabel", "startLabel"] {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .copySBold
            label.text = "SceneLocationView.\(attr)".localized
            label.textColor = .mainGrey
            addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: prevLabel == nil ? topAnchor : prevLabel.bottomAnchor, constant: prevLabel == nil ? 0 : 10),
                label.leftAnchor.constraint(equalTo: leftAnchor)
            ])
            prevLabel = label

            let valueLabel = UILabel()
            valueLabel.translatesAutoresizingMaskIntoConstraints = false
            valueLabel.font = .copySRegular
            valueLabel.textColor = .mainGrey
            addSubview(valueLabel)
            NSLayoutConstraint.activate([
                valueLabel.firstBaselineAnchor.constraint(equalTo: label.firstBaselineAnchor),
                valueLabel.leftAnchor.constraint(equalTo: label.rightAnchor)
            ])
            setValue(valueLabel, forKey: attr)
        }
        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: prevLabel.bottomAnchor, constant: 10)
        ])
    }

    func configure(from scene: Scene) {
        gpsLabel.text = scene.latLngString
        zipLabel.text = scene.zip
        startLabel.text = scene.createdAt?.description
    }
}
