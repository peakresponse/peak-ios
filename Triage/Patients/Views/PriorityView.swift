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
        // top row
        let topStackView = createButtonRow(from: 0, to: 3)
        NSLayoutConstraint.activate([
            topStackView.topAnchor.constraint(equalTo: topAnchor),
            topStackView.leftAnchor.constraint(equalTo: leftAnchor),
            topStackView.rightAnchor.constraint(equalTo: rightAnchor)
        ])

        let bottomStackView = createButtonRow(from: 3, to: 6)
        NSLayoutConstraint.activate([
            bottomStackView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 7),
            bottomStackView.leftAnchor.constraint(equalTo: leftAnchor),
            bottomStackView.rightAnchor.constraint(equalTo: rightAnchor),
            bottomAnchor.constraint(equalTo: bottomStackView.bottomAnchor)
        ])
    }

    private func createButtonRow(from: Int, to: Int) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 7
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        // add the buttons, with containing views for sizing
        for index in from..<to {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(view)
            NSLayoutConstraint.activate([
                view.heightAnchor.constraint(equalToConstant: 46)
            ])

            if index < 5 {
                let button = UIButton(type: .custom)
                button.setTitle("TriagePriority.\(index)".localized, for: .normal)
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
        }
        return stackView
    }

    @objc func buttonPressed(_ button: UIButton) {
        if let priority = buttons.firstIndex(of: button) {
            delegate?.priorityView?(self, didSelect: priority)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func select(priority: Int?) {
        for (index, button) in buttons.enumerated() {
            if index == priority {
                button.superview?.layer.zPosition = 0
                for constraint in button.superview?.constraints ?? [] {
                    if constraint.firstItem?.isKind(of: UIButton.self) ?? false {
                        switch constraint.firstAttribute {
                        case .top:
                            constraint.constant = -5
                        case .right:
                            constraint.constant = 10
                        case .bottom:
                            constraint.constant = 5
                        case .left:
                            constraint.constant = -10
                        default:
                            break
                        }
                    }
                }
            } else {
                button.superview?.layer.zPosition = -1
                for constraint in button.superview?.constraints ?? [] {
                    if constraint.firstItem?.isKind(of: UIButton.self) ?? false {
                        constraint.constant = 0
                    }
                }
            }
        }
    }
}
