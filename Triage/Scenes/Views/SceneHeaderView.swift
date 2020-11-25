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
    weak var approxPatientsCountLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // swiftlint:disable:next function_body_length
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
            descLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor)
        ])
        self.descLabel = descLabel

        let approxPatientsLabel = UILabel()
        approxPatientsLabel.translatesAutoresizingMaskIntoConstraints = false
        approxPatientsLabel.font = .copySBold
        approxPatientsLabel.text = "SceneHeaderView.approxPatientsLabel".localized
        approxPatientsLabel.textColor = .mainGrey
        addSubview(approxPatientsLabel)
        NSLayoutConstraint.activate([
            approxPatientsLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 14),
            approxPatientsLabel.leftAnchor.constraint(equalTo: descLabel.leftAnchor)
        ])

        let approxPatientsCountLabel = UILabel()
        approxPatientsCountLabel.translatesAutoresizingMaskIntoConstraints = false
        approxPatientsCountLabel.font = .copySRegular
        approxPatientsCountLabel.textColor = .mainGrey
        addSubview(approxPatientsCountLabel)
        NSLayoutConstraint.activate([
            approxPatientsCountLabel.firstBaselineAnchor.constraint(equalTo: approxPatientsLabel.firstBaselineAnchor),
            approxPatientsCountLabel.leftAnchor.constraint(equalTo: approxPatientsLabel.rightAnchor),
            bottomAnchor.constraint(equalTo: approxPatientsCountLabel.bottomAnchor, constant: 10)
        ])
        self.approxPatientsCountLabel = approxPatientsCountLabel
    }

    func configure(from scene: Scene) {
        nameLabel.text = scene.name?.isEmpty ?? true ? " " : scene.name
        descLabel.text = scene.desc?.isEmpty ?? true ? " " : scene.desc
        approxPatientsCountLabel.text = scene.approxPatients.value != nil ? "\(scene.approxPatients.value ?? 0)" : "-"
    }
}
