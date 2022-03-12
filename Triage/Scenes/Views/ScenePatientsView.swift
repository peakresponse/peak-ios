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
    private var approxCountViews: [ScenePatientCountView] = []
    private var countViews: [ScenePatientCountView] = []

    var didUpdateApproxPatientsCounts: ((_ priority: Priority?, _ delta: Int) -> Void)?
    var isEditing = false {
        didSet { setEditing() }
    }

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
        backgroundColor = .bgBackground

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .copyMBold
        titleLabel.text = "ScenePatientsView.titleLabel".localized.uppercased()
        titleLabel.textColor = .lowPriorityGrey
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -22)
        ])

        let approxView = UIView()
        approxView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(approxView)
        NSLayoutConstraint.activate([
            approxView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            approxView.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            approxView.widthAnchor.constraint(equalToConstant: 180)
        ])

        let approxLabel = UILabel()
        approxLabel.translatesAutoresizingMaskIntoConstraints = false
        approxLabel.font = .copyXSBold
        approxLabel.text = "ScenePatientsView.approxLabel".localized.uppercased()
        approxLabel.textAlignment = .center
        approxLabel.textColor = .mainGrey
        approxView.addSubview(approxLabel)
        NSLayoutConstraint.activate([
            approxLabel.topAnchor.constraint(equalTo: approxView.topAnchor),
            approxLabel.leftAnchor.constraint(equalTo: approxView.leftAnchor),
            approxLabel.rightAnchor.constraint(equalTo: approxView.rightAnchor)
        ])

        var prevView: UIView = approxLabel
        var countView: ScenePatientCountView
        for i in 0..<7 {
            countView = ScenePatientCountView(style: .approx, priority: i == 0 ? nil : Priority(rawValue: i - 1))
            countView.translatesAutoresizingMaskIntoConstraints = false
            countView.isEditing = true
            countView.didDecrement = { [weak self] in
                self?.didDecrement(index: i)
            }
            countView.didIncrement = { [weak self] in
                self?.didIncrement(index: i)
            }
            approxView.addSubview(countView)
            NSLayoutConstraint.activate([
                countView.topAnchor.constraint(equalTo: prevView.bottomAnchor, constant: i == 0 ? 6 : 25),
                countView.leftAnchor.constraint(equalTo: approxView.leftAnchor),
                countView.rightAnchor.constraint(equalTo: approxView.rightAnchor)
            ])
            prevView = countView
            approxCountViews.append(countView)
        }
        approxView.bottomAnchor.constraint(equalTo: prevView.bottomAnchor).isActive = true

        let patientsView = UIView()
        patientsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(patientsView)
        NSLayoutConstraint.activate([
            patientsView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            patientsView.rightAnchor.constraint(equalTo: rightAnchor, constant: -22),
            patientsView.widthAnchor.constraint(equalToConstant: 110),
            bottomAnchor.constraint(equalTo: patientsView.bottomAnchor, constant: 22)
        ])

        let patientsLabel = UILabel()
        patientsLabel.translatesAutoresizingMaskIntoConstraints = false
        patientsLabel.font = .copyXSBold
        patientsLabel.text = "ScenePatientsView.patientsLabel".localized.uppercased()
        patientsLabel.textAlignment = .center
        patientsLabel.textColor = .mainGrey
        patientsView.addSubview(patientsLabel)
        NSLayoutConstraint.activate([
            patientsLabel.topAnchor.constraint(equalTo: patientsView.topAnchor),
            patientsLabel.leftAnchor.constraint(equalTo: patientsView.leftAnchor),
            patientsLabel.rightAnchor.constraint(equalTo: patientsView.rightAnchor)
        ])

        prevView = patientsLabel
        for i in 0..<7 {
            countView = ScenePatientCountView(style: .normal, priority: i == 0 ? nil : Priority(rawValue: i - 1))
            countView.translatesAutoresizingMaskIntoConstraints = false
            if i > 0 {
                countView.priority = Priority(rawValue: i - 1)
            }
            patientsView.addSubview(countView)
            NSLayoutConstraint.activate([
                countView.topAnchor.constraint(equalTo: prevView.bottomAnchor, constant: i == 0 ? 6 : 25),
                countView.leftAnchor.constraint(equalTo: patientsView.leftAnchor),
                countView.rightAnchor.constraint(equalTo: patientsView.rightAnchor)
            ])
            prevView = countView
            countViews.append(countView)
        }
        patientsView.bottomAnchor.constraint(equalTo: prevView.bottomAnchor).isActive = true

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
        approxCountViews[0].setValue(scene.approxPatientsCount ?? 0)
        if let approxPriorityPatientsCounts = scene.approxPriorityPatientsCounts {
            var total = 0
            for (index, count) in approxPriorityPatientsCounts.enumerated() {
                approxCountViews[index + 1].setValue(count)
                total += count
            }
            approxCountViews[0].setBottomValue(total)
        }

        countViews[0].setValue(scene.patientsCount ?? 0)
        if let priorityPatientsCounts = scene.priorityPatientsCounts {
            for (index, count) in priorityPatientsCounts.enumerated() {
                countViews[index + 1].setValue(count)
            }
        }
    }

    private func setEditing() {
        for countView in approxCountViews {
            countView.isEditing = isEditing
        }
    }

    private func didDecrement(index: Int) {
        didUpdateApproxPatientsCounts?(Priority(rawValue: index - 1), -1)
    }

    private func didIncrement(index: Int) {
        didUpdateApproxPatientsCounts?(Priority(rawValue: index - 1), 1)
    }
}
