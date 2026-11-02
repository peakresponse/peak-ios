//
//  TransportConfirmViewController.swift
//  Triage
//
//  Created by Francis Li on 3/8/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

@objc protocol TransportConfirmViewControllerDelegate {
    @objc optional func transportConfirmViewControllerDidCancel(_ vc: TransportConfirmViewController)
    @objc optional func transportConfirmViewControllerDidConfirm(_ vc: TransportConfirmViewController)
}

class TransportConfirmViewController: UIViewController {
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var confirmButton: PRKit.Button!

    weak var delegate: TransportConfirmViewControllerDelegate?
    var cart: TransportCart?

    init() {
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .coverVertical
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .clear
        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leftAnchor.constraint(equalTo: view.leftAnchor),
            backgroundView.rightAnchor.constraint(equalTo: view.rightAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.backgroundView = backgroundView

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .background
        contentView.clipsToBounds = true
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.cornerRadius = 16
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.contentView = contentView

        let commandHeader = CommandHeader()
        commandHeader.translatesAutoresizingMaskIntoConstraints = false
        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "Button.cancel".localized, style: .plain,
                                                          target: self, action: #selector(cancelPressed))
        contentView.addSubview(commandHeader)
        NSLayoutConstraint.activate([
            commandHeader.topAnchor.constraint(equalTo: contentView.topAnchor),
            commandHeader.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            commandHeader.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])
        self.commandHeader = commandHeader

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 6
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: commandHeader.bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)
        ])
        self.stackView = stackView

        let confirmButton = PRKit.Button()
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.style = .primary
        confirmButton.size = .medium
        confirmButton.setTitle("Button.confirm".localized, for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmPressed), for: .touchUpInside)
        contentView.addSubview(confirmButton)
        NSLayoutConstraint.activate([
            confirmButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 40),
            confirmButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            confirmButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            confirmButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        self.confirmButton = confirmButton

        guard let cart = cart else { return }

        for report in cart.reports {
            let field = TransportCartReportField()
            field.disclosureIndicatorView.widthAnchor.constraint(equalToConstant: 0).isActive = true
            field.configure(from: report)
            stackView.addArrangedSubview(field)
        }

        var view = UIView()
        view.heightAnchor.constraint(equalToConstant: 8).isActive = true
        stackView.addArrangedSubview(view)

        if let responder = cart.responder {
            let field = TransportCartResponderField()
            field.disclosureIndicatorView.widthAnchor.constraint(equalToConstant: 0).isActive = true
            field.configure(from: responder)
            stackView.addArrangedSubview(field)
        }

        view = UIView()
        view.heightAnchor.constraint(equalToConstant: 8).isActive = true
        stackView.addArrangedSubview(view)

        if let facility = cart.facility {
            let field = TransportCartFacilityField()
            field.configure(from: facility)
            stackView.addArrangedSubview(field)
        }
    }

    @IBAction
    func cancelPressed() {
        delegate?.transportConfirmViewControllerDidCancel?(self)
    }

    @IBAction
    func confirmPressed() {
        delegate?.transportConfirmViewControllerDidConfirm?(self)
    }
}
