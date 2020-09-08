//
//  SceneRespondersView.swift
//  Triage
//
//  Created by Francis Li on 9/2/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class SceneRespondersView: UIView {
    weak var countLabel: UILabel!
    weak var respondersLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .bgBackground

        let countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = .copyXXLBold
        countLabel.text = "0"
        countLabel.textColor = .mainGrey
        addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            countLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            bottomAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 10)
        ])
        self.countLabel = countLabel

        let respondersLabel = UILabel()
        respondersLabel.translatesAutoresizingMaskIntoConstraints = false
        respondersLabel.font = .copySBold
        respondersLabel.text = "SceneRespondersView.respondersLabel".localized
        respondersLabel.textColor = .mainGrey
        addSubview(respondersLabel)
        NSLayoutConstraint.activate([
            respondersLabel.firstBaselineAnchor.constraint(equalTo: countLabel.firstBaselineAnchor),
            respondersLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 80)
        ])
        self.respondersLabel = respondersLabel

        let hr = HorizontalRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hr)
        NSLayoutConstraint.activate([
            hr.leftAnchor.constraint(equalTo: leftAnchor),
            hr.rightAnchor.constraint(equalTo: rightAnchor),
            hr.bottomAnchor.constraint(equalTo: bottomAnchor),
            hr.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    func configure(from scene: Scene) {
        countLabel.text = "\(scene.respondersCount.value ?? 0)"
    }
}
