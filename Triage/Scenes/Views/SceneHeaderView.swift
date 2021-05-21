//
//  SceneHeaderView.swift
//  Triage
//
//  Created by Francis Li on 9/2/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class SceneHeaderView: UIView {
    weak var nameLabel: UILabel!
    weak var descLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .white

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .copyMBold
        nameLabel.textColor = .mainGrey
        addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 102),
            nameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            nameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -22)
        ])
        self.nameLabel = nameLabel

        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .copySRegular
        descLabel.textColor = .mainGrey
        addSubview(descLabel)
        NSLayoutConstraint.activate([
            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            descLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            descLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor),
            bottomAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 10)
        ])
        self.descLabel = descLabel
    }

    func configure(from scene: Scene) {
        nameLabel.text = scene.name?.isEmpty ?? true ? " " : scene.name
        descLabel.text = scene.desc?.isEmpty ?? true ? " " : scene.desc
    }
}
