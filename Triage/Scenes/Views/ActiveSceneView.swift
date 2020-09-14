//
//  ActiveSceneView.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import GoogleMaps
import UIKit

@IBDesignable
class ActiveSceneView: UIView {
    var id: String?
    
    var isMaximized = false
    var bottomHeaderViewConstraint: NSLayoutConstraint!
    var bottomBodyViewConstraint: NSLayoutConstraint!
    
    weak var headerView: UIView!
    weak var iconView: UIImageView!
    weak var nameLabel: UILabel!
    weak var descLabel: UILabel!
    
    weak var bodyView: UIView!
    weak var mapView: GMSMapView!
    weak var dateLabel: UILabel!
    weak var patientsCountLabel: UILabel!
    weak var patientsLabel: UILabel!
    weak var transportedCountLabel: UILabel!
    weak var transportedLabel: UILabel!
    weak var respondersCountLabel: UILabel!
    weak var respondersLabel: UILabel!
    weak var joinButton: FormButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        let headerView = UIView()
        headerView.backgroundColor = .orangeAccent
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leftAnchor.constraint(equalTo: leftAnchor),
            headerView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        self.headerView = headerView

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(headerPressed))
        headerView.addGestureRecognizer(tapGestureRecognizer)
        
        let iconView = UIImageView(image: UIImage(named: "Maximize"), highlightedImage: UIImage(named: "Minimize"))
        iconView.tintColor = .white
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        headerView.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -20),
            iconView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10)
        ])
        self.iconView = iconView
        
        let nameLabel = UILabel()
        nameLabel.font = .copyMBold
        nameLabel.numberOfLines = 1
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            nameLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 20),
            nameLabel.rightAnchor.constraint(equalTo: iconView.leftAnchor, constant: -22)
        ])
        self.nameLabel = nameLabel

        let descLabel = UILabel()
        descLabel.font = .copyXSBold
        descLabel.numberOfLines = 1
        descLabel.textColor = .white
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(descLabel)
        NSLayoutConstraint.activate([
            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            descLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            descLabel.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -20),
            headerView.bottomAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 10)
        ])
        self.descLabel = descLabel

        bottomHeaderViewConstraint = bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        bottomHeaderViewConstraint.isActive = true

        let bodyView = UIView()
        bodyView.isHidden = true
        bodyView.backgroundColor = .white
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bodyView)
        NSLayoutConstraint.activate([
            bodyView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            bodyView.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            bodyView.rightAnchor.constraint(equalTo: headerView.rightAnchor)
        ])
        self.bodyView = bodyView

        let mapView = GMSMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: bodyView.topAnchor),
            mapView.leftAnchor.constraint(equalTo: bodyView.leftAnchor),
            mapView.rightAnchor.constraint(equalTo: bodyView.rightAnchor),
            mapView.heightAnchor.constraint(equalToConstant: 145)
        ])
        self.mapView = mapView

        let joinButton = FormButton(size: .xsmall, style: .priority)
        joinButton.buttonLabel = "Button.joinScene".localized
        joinButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        bodyView.addSubview(joinButton)
        NSLayoutConstraint.activate([
            joinButton.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 10),
            joinButton.rightAnchor.constraint(equalTo: bodyView.rightAnchor, constant: -20)
        ])
        self.joinButton = joinButton
        
        let dateLabel = UILabel()
        dateLabel.font = .copySBold
        dateLabel.textColor = .greyPeakBlue
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyView.addSubview(dateLabel)
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 10),
            dateLabel.leftAnchor.constraint(equalTo: bodyView.leftAnchor, constant: 20),
            dateLabel.rightAnchor.constraint(equalTo: joinButton.leftAnchor, constant: -22)
        ])
        self.dateLabel = dateLabel

        let patientsCountLabel = UILabel()
        patientsCountLabel.font = .copySBold
        patientsCountLabel.textColor = .mainGrey
        patientsCountLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyView.addSubview(patientsCountLabel)
        NSLayoutConstraint.activate([
            patientsCountLabel.leftAnchor.constraint(equalTo: dateLabel.leftAnchor),
            patientsCountLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10)
        ])
        self.patientsCountLabel = patientsCountLabel

        let patientsLabel = UILabel()
        patientsLabel.text = "ActiveSceneView.patientsLabel".localized
        patientsLabel.font = .copySRegular
        patientsLabel.textColor = .mainGrey
        patientsLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyView.addSubview(patientsLabel)
        NSLayoutConstraint.activate([
            patientsLabel.leftAnchor.constraint(equalTo: patientsCountLabel.rightAnchor),
            patientsLabel.firstBaselineAnchor.constraint(equalTo: patientsCountLabel.firstBaselineAnchor),
            patientsLabel.rightAnchor.constraint(equalTo: dateLabel.rightAnchor)
        ])
        self.patientsLabel = patientsLabel

        let transportedCountLabel = UILabel()
        transportedCountLabel.font = .copySBold
        transportedCountLabel.textColor = .mainGrey
        transportedCountLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyView.addSubview(transportedCountLabel)
        NSLayoutConstraint.activate([
            transportedCountLabel.leftAnchor.constraint(equalTo: patientsCountLabel.leftAnchor),
            transportedCountLabel.topAnchor.constraint(equalTo: patientsCountLabel.bottomAnchor, constant: 10)
        ])
        self.transportedCountLabel = transportedCountLabel
        
        let transportedLabel = UILabel()
        transportedLabel.text = "ActiveSceneView.transportedLabel".localized
        transportedLabel.font = .copySRegular
        transportedLabel.textColor = .mainGrey
        transportedLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyView.addSubview(transportedLabel)
        NSLayoutConstraint.activate([
            transportedLabel.leftAnchor.constraint(equalTo: transportedCountLabel.rightAnchor),
            transportedLabel.firstBaselineAnchor.constraint(equalTo: transportedCountLabel.firstBaselineAnchor),
            transportedLabel.rightAnchor.constraint(equalTo: bodyView.rightAnchor, constant: -20)
        ])
        self.transportedLabel = transportedLabel
        
        let respondersCountLabel = UILabel()
        respondersCountLabel.font = .copySBold
        respondersCountLabel.textColor = .mainGrey
        respondersCountLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyView.addSubview(respondersCountLabel)
        NSLayoutConstraint.activate([
            respondersCountLabel.leftAnchor.constraint(equalTo: transportedCountLabel.leftAnchor),
            respondersCountLabel.topAnchor.constraint(equalTo: transportedCountLabel.bottomAnchor, constant: 10)
        ])
        self.respondersCountLabel = respondersCountLabel
        
        let respondersLabel = UILabel()
        respondersLabel.text = "ActiveSceneView.respondersLabel".localized
        respondersLabel.font = .copySRegular
        respondersLabel.textColor = .mainGrey
        respondersLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyView.addSubview(respondersLabel)
        NSLayoutConstraint.activate([
            respondersLabel.leftAnchor.constraint(equalTo: respondersCountLabel.rightAnchor),
            respondersLabel.firstBaselineAnchor.constraint(equalTo: respondersCountLabel.firstBaselineAnchor),
            respondersLabel.rightAnchor.constraint(equalTo: bodyView.rightAnchor, constant: -20),
            bodyView.bottomAnchor.constraint(equalTo: respondersCountLabel.bottomAnchor, constant: 44)
        ])
        self.respondersLabel = respondersLabel

        bottomBodyViewConstraint = bottomAnchor.constraint(equalTo: bodyView.bottomAnchor)
    }

    @objc func headerPressed() {
        isMaximized = !isMaximized
        if isMaximized {
            bottomHeaderViewConstraint.isActive = false
            bottomBodyViewConstraint.isActive = true
            bodyView.isHidden = false
            iconView.isHighlighted = true
        } else {
            bottomBodyViewConstraint.isActive = false
            bottomHeaderViewConstraint.isActive = true
            bodyView.isHidden = true
            iconView.isHighlighted = false
        }
    }

    @objc func buttonPressed() {
        if let id = id {
            AppDelegate.enterScene(id: id)
        }
    }

    func configure(from scene: Scene) {
        id = scene.id
        nameLabel.text = (scene.name ?? "").isEmpty ? " " : scene.name
        descLabel.text = (scene.desc ?? "").isEmpty ? " " : scene.desc
        if let target = scene.latLng {
            mapView.camera = GMSCameraPosition(target: target, zoom: 15)
            mapView.clear()
            let marker = GMSMarker(position: target)
            marker.icon = GMSMarker.customMarkerImage
            marker.map = mapView
        }
        dateLabel.text = scene.createdAt?.asTimeDateString()
        patientsCountLabel.text = "\(scene.patientsCount.value ?? 0)"
        transportedCountLabel.text = "\(scene.priorityPatientsCounts?[5] ?? 0)"
        respondersCountLabel.text = "\(scene.respondersCount.value ?? 0)"
    }
}
