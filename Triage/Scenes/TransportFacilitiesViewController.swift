//
//  TransportFacilitiesViewController.swift
//  Triage
//
//  Created by Francis Li on 3/6/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

@objc protocol TransportFacilitiesViewControllerDelegate {
    @objc optional func transportFacilitiesViewController(_ vc: TransportFacilitiesViewController, didRemoveReport report: Report?)
    @objc optional func transportFacilitiesViewController(_ vc: TransportFacilitiesViewController, didRemoveResponder responder: Responder?)
    @objc optional func transportFacilitiesViewController(_ vc: TransportFacilitiesViewController, didSelect facility: Facility?)
}

class TransportFacilitiesViewController: UIViewController, TransportCartViewController, PRKit.FormFieldDelegate,
                                         UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var transportButton: PRKit.RoundButton!

    weak var delegate: TransportFacilitiesViewControllerDelegate?
    var cart: TransportCart?

    override func viewDidLoad() {
        super.viewDidLoad()

        transportButton.titleLabel?.font = UIFont(name: "Barlow-SemiBold", size: 18) ?? .boldSystemFont(ofSize: 18)

        updateCart()
    }

    func updateCart() {
        guard let cart = cart, let stackView = stackView else { return }
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        if cart.reports.count > 0 || cart.responder != nil {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.heightAnchor.constraint(equalToConstant: 6).isActive = true
            stackView.addArrangedSubview(view)
            for report in cart.reports {
                let field = TransportCartReportField()
                field.delegate = self
                field.configure(from: report)
                stackView.addArrangedSubview(field)
            }
            if let responder = cart.responder {
                let field = TransportCartResponderField()
                field.delegate = self
                field.configure(from: responder)
                stackView.addArrangedSubview(field)
            }
        } else {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.heightAnchor.constraint(equalToConstant: 0).isActive = true
            stackView.addArrangedSubview(view)
        }

        transportButton.isEnabled = cart.reports.count > 0 && cart.responder != nil && cart.facility != nil
    }

    @IBAction
    func transportPressed(_ sender: RoundButton) {

    }

    // MARK: - FormFieldDelegate

    func formFieldDidPress(_ field: FormField) {
        if let field = field as? TransportCartReportField {
            delegate?.transportFacilitiesViewController?(self, didRemoveReport: field.report)
        } else if let field = field as? TransportCartResponderField {
            delegate?.transportFacilitiesViewController?(self, didRemoveResponder: field.responder)
        }
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
//        return results?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Facility", for: indexPath)
//        if let cell = cell as? TransportResponderCollectionViewCell {
//            let responder = results?[indexPath.row]
//            cell.configure(from: responder, index: indexPath.row, isSelected: responder == cart?.responder)
//        }
        return cell
    }
}
