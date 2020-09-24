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
    weak var urgencyLabel: UILabel!
    
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
            approxPatientsCountLabel.leftAnchor.constraint(equalTo: approxPatientsLabel.rightAnchor)
        ])
        self.approxPatientsCountLabel = approxPatientsCountLabel
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copySBold
        label.text = "SceneHeaderView.urgencyLabel".localized
        label.textColor = .mainGrey
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: approxPatientsLabel.bottomAnchor, constant: 14),
            label.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            label.rightAnchor.constraint(equalTo: nameLabel.rightAnchor)
        ])

        let urgencyLabel = UILabel()
        urgencyLabel.translatesAutoresizingMaskIntoConstraints = false
        urgencyLabel.font = .copySRegular
        urgencyLabel.textColor = .mainGrey
        addSubview(urgencyLabel)
        NSLayoutConstraint.activate([
            urgencyLabel.topAnchor.constraint(equalTo: label.bottomAnchor),
            urgencyLabel.leftAnchor.constraint(equalTo: label.leftAnchor),
            urgencyLabel.rightAnchor.constraint(equalTo: label.rightAnchor),
            bottomAnchor.constraint(equalTo: urgencyLabel.bottomAnchor, constant: 10)
        ])
        self.urgencyLabel = urgencyLabel
    }

    func configure(from scene: Scene) {
        nameLabel.text = scene.name?.isEmpty ?? true ? " " : scene.name
        descLabel.text = scene.desc?.isEmpty ?? true ? " " : scene.desc
        approxPatientsCountLabel.text = scene.approxPatients.value != nil ? "\(scene.approxPatients.value ?? 0)" : "-"
        urgencyLabel.text = scene.urgency?.isEmpty ?? true ? " " : scene.urgency
    }
}
