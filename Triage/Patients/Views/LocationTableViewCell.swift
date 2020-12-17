//
//  LocationTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 8/11/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class LocationTableViewCell: AttributeTableViewCell {
    var activityIndicatorView: UIActivityIndicatorView!

    override func configure(from patient: Patient) {
        super.configure(from: patient)

        let field = fields[0]
        if activityIndicatorView == nil {
            field.alertLabel.textColor = .greyPeakBlue
            addAlertLabelTapRecognizer(to: field)

            activityIndicatorView = .withMediumStyle()
            activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            activityIndicatorView.color = .mainGrey
            contentView.addSubview(activityIndicatorView)
            NSLayoutConstraint.activate([
                activityIndicatorView.centerYAnchor.constraint(equalTo: field.textField.centerYAnchor),
                activityIndicatorView.rightAnchor.constraint(equalTo: field.textField.rightAnchor, constant: -22)
            ])
            activityIndicatorView.hidesWhenStopped = true
        }
        field.alertLabel.text = patient.hasLatLng ? "Location.viewOnMap".localized : (isEditing ? "Location.capture".localized : nil)
        field.alertLabel.isHidden = false
        field.detailLabel.text = patient.latLngString
    }

    func setCapturing(_ isCapturing: Bool) {
        let field = fields[0]
        if isCapturing {
            activityIndicatorView.startAnimating()
            field.alertLabel.isHidden = true
        } else {
            activityIndicatorView.stopAnimating()
            field.alertLabel.isHidden = false
        }
    }
}
