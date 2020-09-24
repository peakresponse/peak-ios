//
//  SceneTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 9/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import GoogleMaps
import UIKit

class SceneTableViewCell: UITableViewCell {
    weak var containerView: UIView!
    weak var mapView: GMSMapView!
    weak var headerView: UIView!
    weak var bodyView: UIView!
    weak var dateLabel: UILabel!
    weak var nameLabel: UILabel!
    weak var descLabel: UILabel!
    weak var patientsLabel: UILabel!
    weak var respondersLabel: UILabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 4
        containerView.addShadow(withOffset: CGSize(width: 0, height: 6), radius: 10, color: .black, opacity: 0.15)
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            containerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            containerView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -22),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 7)
        ])
        self.containerView = containerView

        let mapView = GMSMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = 4
        mapView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        containerView.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: containerView.topAnchor),
            mapView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            mapView.widthAnchor.constraint(equalToConstant: 115),
            mapView.heightAnchor.constraint(equalToConstant: 110),
            containerView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor)
        ])
        self.mapView = mapView

        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.layer.cornerRadius = 4
        headerView.layer.maskedCorners = [.layerMaxXMinYCorner]
        headerView.backgroundColor = .lightPeakBlue
        containerView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leftAnchor.constraint(equalTo: mapView.rightAnchor),
            headerView.rightAnchor.constraint(equalTo: containerView.rightAnchor)
        ])
        self.headerView = headerView

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .copyXSRegular
        dateLabel.textColor = .mainGrey
        headerView.addSubview(dateLabel)
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 6),
            dateLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 14),
            dateLabel.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -14)
        ])
        self.dateLabel = dateLabel
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .copySBold
        nameLabel.textColor = .mainGrey
        nameLabel.numberOfLines = 1
        headerView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor),
            nameLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 14),
            nameLabel.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -14)
        ])
        self.nameLabel = nameLabel

        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .copyXSBold
        descLabel.textColor = .mainGrey
        descLabel.numberOfLines = 1
        headerView.addSubview(descLabel)
        NSLayoutConstraint.activate([
            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            descLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            descLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor),
            headerView.bottomAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 8)
        ])
        self.descLabel = descLabel
        
        let bodyView = UIView()
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.layer.cornerRadius = 4
        bodyView.layer.maskedCorners = [.layerMaxXMaxYCorner]
        bodyView.backgroundColor = .white
        containerView.addSubview(bodyView)
        NSLayoutConstraint.activate([
            bodyView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            bodyView.leftAnchor.constraint(equalTo: mapView.rightAnchor),
            bodyView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            bodyView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        let patientsLabel = UILabel()
        patientsLabel.translatesAutoresizingMaskIntoConstraints = false
        patientsLabel.font = .copyXSRegular
        patientsLabel.textColor = .mainGrey
        patientsLabel.numberOfLines = 1
        bodyView.addSubview(patientsLabel)
        NSLayoutConstraint.activate([
            patientsLabel.topAnchor.constraint(equalTo: bodyView.topAnchor, constant: 14),
            patientsLabel.leftAnchor.constraint(equalTo: bodyView.leftAnchor, constant: 14),
            patientsLabel.rightAnchor.constraint(equalTo: bodyView.rightAnchor, constant: -14)
        ])
        self.patientsLabel = patientsLabel
        
        let respondersLabel = UILabel()
        respondersLabel.translatesAutoresizingMaskIntoConstraints = false
        respondersLabel.font = .copyXSRegular
        respondersLabel.textColor = .mainGrey
        respondersLabel.numberOfLines = 1
        bodyView.addSubview(respondersLabel)
        NSLayoutConstraint.activate([
            respondersLabel.topAnchor.constraint(equalTo: patientsLabel.bottomAnchor),
            respondersLabel.leftAnchor.constraint(equalTo: patientsLabel.leftAnchor),
            respondersLabel.rightAnchor.constraint(equalTo: patientsLabel.rightAnchor)
        ])
        self.respondersLabel = respondersLabel
    }

    func configure(from scene: Scene) {
        dateLabel.text = scene.createdAt?.asTimeDateString() ?? " "
        nameLabel.text = scene.name?.isEmpty ?? true ? " " : scene.name
        descLabel.text = scene.desc?.isEmpty ?? true ? " " : scene.desc

        if let target = scene.latLng {
            mapView.camera = GMSCameraPosition(target: target, zoom: 13.5)
            mapView.clear()
            let marker = GMSMarker(position: target)
            marker.icon = GMSMarker.customMarkerImage
            marker.map = mapView
        }

        patientsLabel.text = String(format: "SceneTableViewCell.patientsLabel".localized, scene.patientsCount.value ?? 0)
        respondersLabel.text = String(format: "SceneTableViewCell.respondersLabel".localized, scene.respondersCount.value ?? 0)
    }
}
