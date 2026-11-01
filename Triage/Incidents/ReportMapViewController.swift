//
//  ReportMapViewController.swift
//  Triage
//
//  Created by Francis Li on 6/5/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import GoogleMaps
import PRKit
import UIKit

class ReportMapViewController: BaseViewController {
    weak var commandHeader: CommandHeader!
    weak var mapView: GMSMapView!

    var report: Report!

    override func viewDidLoad() {
        super.viewDidLoad()

        let commandHeader = CommandHeader()
        commandHeader.translatesAutoresizingMaskIntoConstraints = false
        commandHeader.preservesSuperviewLayoutMargins = true
        headerView.addSubview(commandHeader)
        NSLayoutConstraint.activate([
            commandHeader.topAnchor.constraint(equalTo: headerView.topAnchor),
            commandHeader.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            commandHeader.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            commandHeader.contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            commandHeader.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            headerView.bottomAnchor.constraint(equalTo: commandHeader.bottomAnchor)
        ])
        self.commandHeader = commandHeader

        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized, style: .done,
                                                          target: self, action: #selector(dismissAnimated))

        var camera: GMSCameraPosition
        var marker: GMSMarker?
        if let latLng = report.patient?.latLng {
            camera = GMSCameraPosition(latitude: latLng.latitude, longitude: latLng.longitude, zoom: 18)
            marker = GMSMarker()
            marker?.position = latLng
            marker?.title = "#\(report.pin ?? "")"
            marker?.snippet = "\(report.patient?.fullName ?? "")\n\(report.patient?.ageString ?? "") \(report.patient?.genderString ?? "")"
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let priority = TriagePriority(rawValue: report.patient?.priority ?? TriagePriority.unknown.rawValue) {
                marker?.icon = priority.mapMarkerImage
            }
        } else {
            camera = GMSCameraPosition()
        }
        let mapView = GMSMapView(frame: mainView.bounds, camera: camera)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.isMyLocationEnabled = true
        marker?.map = mapView
        mainView.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: mainView.topAnchor),
            mapView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            mapView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            mapView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
        ])
        self.mapView = mapView
    }
}
