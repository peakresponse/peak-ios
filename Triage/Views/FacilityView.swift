//
//  FacilityView.swift
//  Triage
//
//  Created by Francis Li on 8/20/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class FacilityView: UIView {
    let headerView = UIView()
    var headerViewHeightConstraint: NSLayoutConstraint!
    let nameLabel = UILabel()
    let distanceLabel = UILabel()
    let bodyView = UIView()
    let addressLabel = UILabel()

    var name: String? {
        get { return nameLabel.text }
        set { nameLabel.text = newValue }
    }

    var distance: String? {
        get { return distanceLabel.text }
        set { distanceLabel.text = newValue }
    }

    var address: String? {
        get { return addressLabel.text }
        set { addressLabel.text = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        layer.cornerRadius = 5;
        addShadow(withOffset: CGSize(width: 1, height: 2), radius: 2, color: .black, opacity: 0.1)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        headerView.layer.cornerRadius = 5
        headerView.backgroundColor = .lightPeakBlue
        addSubview(headerView)
        headerViewHeightConstraint = headerView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 34.0/78.0)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leftAnchor.constraint(equalTo: leftAnchor),
            headerView.rightAnchor.constraint(equalTo: rightAnchor),
            headerViewHeightConstraint
        ])

        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.font = .copySBold
        distanceLabel.textColor = .greyPeakBlue
        distanceLabel.textAlignment = .right
        distanceLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        headerView.addSubview(distanceLabel)
        NSLayoutConstraint.activate([
            distanceLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            distanceLabel.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -15)
        ])

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .copySBold
        nameLabel.textColor = .mainGrey
        headerView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            nameLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 15),
            nameLabel.rightAnchor.constraint(equalTo: distanceLabel.leftAnchor, constant: -15)
        ])

        bodyView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        bodyView.layer.cornerRadius = 5
        bodyView.backgroundColor = .white
        addSubview(bodyView)
        NSLayoutConstraint.activate([
            bodyView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            bodyView.leftAnchor.constraint(equalTo: leftAnchor),
            bodyView.rightAnchor.constraint(equalTo: rightAnchor),
            bottomAnchor.constraint(equalTo: bodyView.bottomAnchor)
        ])
        
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = .copySBold
        addressLabel.textColor = .lowPriorityGrey
        bodyView.addSubview(addressLabel)
        NSLayoutConstraint.activate([
            addressLabel.centerYAnchor.constraint(equalTo: bodyView.centerYAnchor),
            addressLabel.leftAnchor.constraint(equalTo: bodyView.leftAnchor, constant: 15),
            addressLabel.rightAnchor.constraint(equalTo: bodyView.rightAnchor, constant: -15),
            addressLabel.bottomAnchor.constraint(equalTo: bodyView.bottomAnchor)
        ])
    }
    
    func configure(from facility: Facility) {
        name = facility.name
        address = facility.address
        distance = nil
        if facility.distance < Double.greatestFiniteMagnitude {
            distance = String(format: "%.1f mi", facility.distance.toMiles)
        }
        if !headerViewHeightConstraint.isActive {
            headerViewHeightConstraint.isActive = true
            headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            bodyView.isHidden = false
        }
    }

    func configure(from agency: Agency) {
        name = agency.name
        address = nil
        distance = nil
        if headerViewHeightConstraint.isActive {
            headerViewHeightConstraint.isActive = false
            headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            bodyView.isHidden = true
        }
    }

    func setSelected(_ selected: Bool) {
        headerView.backgroundColor = selected ? .peakBlue : .lightPeakBlue
        nameLabel.textColor = selected ? .white : .mainGrey
        distanceLabel.textColor = selected ? .white : .greyPeakBlue
        bodyView.backgroundColor = selected ? .lowPriorityGrey : .white
        addressLabel.textColor = selected ? .mainGrey : .lowPriorityGrey
    }
}
