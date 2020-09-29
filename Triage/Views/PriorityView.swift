//
//  PriorityView.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

@objc protocol PriorityViewDelegate {
    @objc optional func priorityView(_ view: PriorityView, didSelect priority: Int)
    @objc optional func priorityViewDidDismiss(_ view: PriorityView)
}

class PriorityView: UIView {
    weak var delegate: PriorityViewDelegate?
    var buttons: [UIButton] = []
    var selectedPriority: Int? {
        didSet { select(priority: selectedPriority) }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .bgBackground
        addShadow(withOffset: CGSize(width: 4, height: 4), radius: 20, color: .black, opacity: 0.2)

        // add a close button in upper right corner
        let closeButton = UIButton(type: .custom)
        closeButton.addTarget(self, action: #selector(closePressed), for: .touchUpInside)
        closeButton.setImage(UIImage(named: "Clear"), for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor),
            closeButton.rightAnchor.constraint(equalTo: rightAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // top row
        let topStackView = createButtonRow(from: 0, to: 3)
        NSLayoutConstraint.activate([
            topStackView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 11),
            topStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            topStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -22)
        ])

        let bottomStackView = createButtonRow(from: 3, to: 6)
        NSLayoutConstraint.activate([
            bottomStackView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 11),
            bottomStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            bottomStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -22),
            bottomAnchor.constraint(equalTo: bottomStackView.bottomAnchor, constant: 27)
        ])
    }

    private func createButtonRow(from: Int, to: Int) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 11
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        // add the buttons, with containing views for sizing
        for index in from..<to {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(view)
            NSLayoutConstraint.activate([
                view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 89.0/103.0)
            ])

            let button = UIButton(type: .custom)
            button.setTitle("Patient.priority.\(index)".localized, for: .normal)
            button.setTitleColor(PRIORITY_LABEL_COLORS[index], for: .normal)
            button.titleLabel?.font = .copySBold
            button.setBackgroundImage(UIImage.resizableImage(withColor: PRIORITY_COLORS[index], cornerRadius: 5), for: .normal)
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button)
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: view.topAnchor),
                button.leftAnchor.constraint(equalTo: view.leftAnchor),
                button.rightAnchor.constraint(equalTo: view.rightAnchor),
                button.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            buttons.append(button)
        }
        return stackView
    }

    @objc func closePressed() {
        delegate?.priorityViewDidDismiss?(self)
    }

    @objc func buttonPressed(_ button: UIButton) {
        if let priority = buttons.firstIndex(of: button) {
            if priority == selectedPriority {
                closePressed()
            } else {
                delegate?.priorityView?(self, didSelect: priority)
            }
        }
    }

    func select(priority: Int?) {
        for (index, button) in buttons.enumerated() {
            if index == priority {
                for constraint in button.superview?.constraints ?? [] {
                    if constraint.firstItem?.isKind(of: UIButton.self) ?? false {
                        switch constraint.firstAttribute {
                        case .top, .left:
                            constraint.constant = -5
                        case .right, .bottom:
                            constraint.constant = 5
                        default:
                            break
                        }
                    }
                }
                button.addShadow(withOffset: CGSize(width: 0, height: 10), radius: 40, color: .black, opacity: 0.4)
            } else {
                for constraint in button.superview?.constraints ?? [] {
                    if constraint.firstItem?.isKind(of: UIButton.self) ?? false {
                        constraint.constant = 0
                    }
                }
                button.removeShadow()
            }
        }
    }
}
