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

    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.clipsToBounds = true
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.cornerRadius = 16
        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "Button.cancel".localized, style: .plain, target: self, action: #selector(cancelPressed))

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
            let regionFacility = facility.realm?.objects(RegionFacility.self).filter("regionId=%@ && facility=%@", AppSettings.regionId as Any, facility).first
            let field = CellField()
            field.isLabelHidden = true
            field.text = regionFacility?.facilityName ?? facility.name
            field.disclosureIndicatorView.widthAnchor.constraint(equalToConstant: 0).isActive = true
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
