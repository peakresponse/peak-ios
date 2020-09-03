//
//  ScenePatientsView.swift
//  Triage
//
//  Created by Francis Li on 9/2/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class ScenePatientsView: UIView {
    weak var countLabel: UILabel!
    var countLabels: [UILabel] = []

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
            countLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 22)
        ])
        self.countLabel = countLabel

        let patientsLabel = UILabel()
        patientsLabel.translatesAutoresizingMaskIntoConstraints = false
        patientsLabel.font = .copySBold
        patientsLabel.text = "ScenePatientsView.patientsLabel".localized
        patientsLabel.textColor = .mainGrey
        addSubview(patientsLabel)
        NSLayoutConstraint.activate([
            patientsLabel.firstBaselineAnchor.constraint(equalTo: countLabel.firstBaselineAnchor),
            patientsLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 80)
        ])

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 10),
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -22),
            stackView.heightAnchor.constraint(equalToConstant: 42),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 22)
        ])

        for i in 0..<6 {
            let view = UIView()
            view.layer.cornerRadius = 4
            view.backgroundColor = PRIORITY_COLORS_LIGHTENED[i]
            stackView.addArrangedSubview(view)

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .copyXSRegular
            label.text = "Patient.priority.abbrev.\(i)".localized
            label.textAlignment = .center
            label.textColor = .mainGrey
            label.numberOfLines = 1
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: view.topAnchor, constant: 3),
                label.leftAnchor.constraint(equalTo: view.leftAnchor),
                label.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])

            let countLabel = UILabel()
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            countLabel.font = .copyMBold
            countLabel.text = "-"
            countLabel.textAlignment = .center
            countLabel.textColor = .mainGrey
            countLabel.numberOfLines = 1
            view.addSubview(countLabel)
            NSLayoutConstraint.activate([
                countLabel.topAnchor.constraint(equalTo: label.bottomAnchor),
                countLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
                countLabel.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
        }

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
        
    }
}
