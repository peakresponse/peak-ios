//
//  AlertViewController.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class AlertViewControllerAction: UIAlertAction {
    var handler: ((UIAlertAction) -> Void)?
}

class AlertViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!

    var alertTitle: String? {
        didSet { titleLabel?.text = alertTitle }
    }
    var alertMessage: String? {
        didSet { messageLabel?.text = alertMessage }
    }
    var alertActions: [AlertViewControllerAction] = []

    init() {
        super.init(nibName: "AlertViewController", bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        containerView.addShadow(withOffset: CGSize(width: 0, height: 10), radius: 40, color: .black, opacity: 0.4)
        titleLabel.text = alertTitle
        messageLabel.text = alertMessage

        for action in alertActions {
            let button = FormButton(size: .small, style: action.style == .cancel ? .lowPriority : .priority)
            button.buttonLabel = action.title
            button.userData = action
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
    }

    func addAlertAction(title: String?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?) {
        let action = AlertViewControllerAction(title: title, style: style, handler: handler)
        action.handler = handler
        alertActions.append(action)
    }

    @objc func buttonPressed(_ button: UIButton) {
        if let formButton = stackView.arrangedSubviews.first(where: { ($0 as? FormButton)?.button == button }) as? FormButton {
            if let action = formButton.userData as? AlertViewControllerAction {
                if let handler = action.handler {
                    handler(action)
                } else if action.style == .cancel {
                    dismissAnimated()
                }
            }
        }
    }
}
