//
//  ScenePatientCountView.swift
//  Triage
//
//  Created by Francis Li on 5/20/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit

enum ScenePatientCountViewStyle {
    case normal
    case approx
}

class ScenePatientCountView: UIView {
    var view: UIView!
    var label: UILabel!
    var countLabel: UILabel!
    var decrButton: UIButton!
    var incrButton: UIButton!

    var borderView: UIView!
    var bottomView: UIView!
    var bottomLabel: UILabel!
    var bottomCountLabel: UILabel!

    var style: ScenePatientCountViewStyle = .normal {
        didSet { updateStyle() }
    }
    var priority: Priority? {
        didSet { updateStyle() }
    }
    var isEditing = false {
        didSet { setEditing() }
    }

    var didIncrement: (() -> Void)?
    var didDecrement: (() -> Void)?

    init(style: ScenePatientCountViewStyle, priority: Priority? = nil) {
        super.init(frame: .zero)
        self.style = style
        self.priority = priority
        commonInit()
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
        layer.cornerRadius = 10
        layer.masksToBounds = true

        view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leftAnchor.constraint(equalTo: leftAnchor),
            view.rightAnchor.constraint(equalTo: rightAnchor)
        ])

        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copyXSBold
        label.textAlignment = .center
        label.textColor = .lowPriorityGrey
        label.numberOfLines = 1
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 3),
            label.leftAnchor.constraint(equalTo: view.leftAnchor),
            label.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])

        countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = .copyXLBold
        countLabel.text = "0"
        countLabel.textAlignment = .center
        countLabel.textColor = .mainGrey
        countLabel.numberOfLines = 1
        view.addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: priority == nil && style != .approx ? 22 : -6),
            countLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
            countLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
            countLabel.heightAnchor.constraint(equalToConstant: 43),
            view.bottomAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: priority == nil && style != .approx ? 27 : 0)
        ])

        if style == .approx {
            decrButton = UIButton(type: .custom)
            decrButton.translatesAutoresizingMaskIntoConstraints = false
            decrButton.setImage(UIImage(named: "Minimize"), for: .normal)
            decrButton.isHidden = true
            decrButton.addTarget(self, action: #selector(decrPressed), for: .touchUpInside)
            view.addSubview(decrButton)
            NSLayoutConstraint.activate([
                decrButton.topAnchor.constraint(equalTo: view.topAnchor),
                decrButton.leftAnchor.constraint(equalTo: view.leftAnchor),
                decrButton.widthAnchor.constraint(equalToConstant: 50),
                decrButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            incrButton = UIButton(type: .custom)
            incrButton.translatesAutoresizingMaskIntoConstraints = false
            incrButton.setImage(UIImage(named: "Maximize"), for: .normal)
            incrButton.isHidden = true
            incrButton.addTarget(self, action: #selector(incrPressed), for: .touchUpInside)
            view.addSubview(incrButton)
            NSLayoutConstraint.activate([
                incrButton.topAnchor.constraint(equalTo: view.topAnchor),
                incrButton.rightAnchor.constraint(equalTo: view.rightAnchor),
                incrButton.widthAnchor.constraint(equalToConstant: 50),
                incrButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        if priority == nil && style == .approx {
            borderView = UIView()
            borderView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(borderView)
            NSLayoutConstraint.activate([
                borderView.topAnchor.constraint(equalTo: view.bottomAnchor),
                borderView.leftAnchor.constraint(equalTo: leftAnchor),
                borderView.rightAnchor.constraint(equalTo: rightAnchor),
                borderView.heightAnchor.constraint(equalToConstant: 3)
            ])

            bottomView = UIView()
            bottomView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(bottomView)
            NSLayoutConstraint.activate([
                bottomView.topAnchor.constraint(equalTo: borderView.bottomAnchor),
                bottomView.leftAnchor.constraint(equalTo: leftAnchor),
                bottomView.rightAnchor.constraint(equalTo: rightAnchor)
            ])

            bottomLabel = UILabel()
            bottomLabel.translatesAutoresizingMaskIntoConstraints = false
            bottomLabel.font = .copyXSBold
            bottomLabel.textAlignment = .center
            bottomLabel.textColor = .lowPriorityGrey
            bottomLabel.numberOfLines = 1
            bottomView.addSubview(bottomLabel)
            NSLayoutConstraint.activate([
                bottomLabel.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 3),
                bottomLabel.leftAnchor.constraint(equalTo: bottomView.leftAnchor),
                bottomLabel.rightAnchor.constraint(equalTo: bottomView.rightAnchor)
            ])

            bottomCountLabel = UILabel()
            bottomCountLabel.translatesAutoresizingMaskIntoConstraints = false
            bottomCountLabel.font = .copyXLBold
            bottomCountLabel.text = "0"
            bottomCountLabel.textAlignment = .center
            bottomCountLabel.textColor = .mainGrey
            bottomCountLabel.numberOfLines = 1
            bottomView.addSubview(bottomCountLabel)
            NSLayoutConstraint.activate([
                bottomCountLabel.topAnchor.constraint(equalTo: bottomLabel.bottomAnchor, constant: -6),
                bottomCountLabel.leftAnchor.constraint(equalTo: bottomView.leftAnchor),
                bottomCountLabel.rightAnchor.constraint(equalTo: bottomView.rightAnchor),
                bottomCountLabel.heightAnchor.constraint(equalToConstant: 43),
                bottomView.bottomAnchor.constraint(equalTo: bottomCountLabel.bottomAnchor, constant: 0)
            ])
            bottomAnchor.constraint(equalTo: bottomView.bottomAnchor).isActive = true
        } else {
            bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }

        updateStyle()
    }

    private func updateStyle() {
        if let priority = priority {
            label.text = priority.description.uppercased()
        } else {
            label.text = "ScenePatientCountView.total".localized.uppercased()
            if style == .approx {
                bottomLabel.text = "ScenePatientCountView.triageTotal".localized.uppercased()
            }
        }
        switch style {
        case .approx:
            backgroundColor = .white
            layer.borderWidth = 3
            if let priority = priority {
                layer.borderColor = priority.color.cgColor
                decrButton.setBackgroundImage(UIImage.resizableImage(withColor: priority.color, cornerRadius: 0), for: .normal)
                incrButton.setBackgroundImage(UIImage.resizableImage(withColor: priority.color, cornerRadius: 0), for: .normal)
            } else {
                layer.borderColor = UIColor.greyPeakBlue.cgColor
                borderView.backgroundColor = .greyPeakBlue
                decrButton.setBackgroundImage(UIImage.resizableImage(withColor: .greyPeakBlue, cornerRadius: 0), for: .normal)
                incrButton.setBackgroundImage(UIImage.resizableImage(withColor: .greyPeakBlue, cornerRadius: 0), for: .normal)
            }
        case .normal:
            layer.borderWidth = 0
            if let priority = priority {
                backgroundColor = priority.lightenedColor
            } else {
                backgroundColor = .lightGreyBlue
            }
        }
    }

    private func setEditing() {
        guard style == .approx else { return }
        if isEditing {
            decrButton.isHidden = false
            incrButton.isHidden = false
        } else {
            decrButton.isHidden = true
            incrButton.isHidden = true
        }
    }

    func setValue(_ value: Int) {
        countLabel.text = "\(value)"
    }

    func setBottomValue(_ value: Int) {
        bottomCountLabel.text = "\(value)"
    }

    @objc func decrPressed() {
        didDecrement?()
    }

    @objc func incrPressed() {
        didIncrement?()
    }
}
