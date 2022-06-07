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

class ReportMapViewController: UIViewController {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var mapContainerView: UIView!
    weak var mapView: GMSMapView!

    var report: Report!

    override func viewDidLoad() {
        super.viewDidLoad()

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
        let mapView = GMSMapView(frame: mapContainerView.bounds, camera: camera)
        mapView.isMyLocationEnabled = true
        marker?.map = mapView
        mapContainerView.addSubview(mapView)
        self.mapView = mapView
    }
}
