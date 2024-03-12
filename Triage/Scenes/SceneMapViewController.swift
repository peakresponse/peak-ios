//
//  SceneMapViewController.swift
//  Triage
//
//  Created by Francis Li on 6/5/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import GoogleMaps
import PRKit
import RealmSwift
import UIKit

class SceneMapViewController: UIViewController, PRKit.FormFieldDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var mapContainerView: UIView!
    weak var mapView: GMSMapView!

    var incident: Incident?
    var results: Results<Report>?
    var notificationToken: NotificationToken?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        tabBarItem.title = "TabBarItem.sceneMap".localized
        tabBarItem.image = UIImage(named: "Pin", in: PRKitBundle.instance, compatibleWith: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if incident == nil, let sceneId = AppSettings.sceneId,
           let scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId) {
            incident = scene.incident.first
        }

        commandHeader.searchField.delegate = self

        var camera: GMSCameraPosition
        if let latLng = incident?.scene?.latLng {
            camera = GMSCameraPosition(latitude: latLng.latitude, longitude: latLng.longitude, zoom: 18)
        } else {
            camera = GMSCameraPosition()
        }

        let mapView = GMSMapView(frame: mapContainerView.bounds, camera: camera)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        mapContainerView.addSubview(mapView)
        self.mapView = mapView

        performQuery()
    }

    @objc func performQuery() {
        guard let incident = incident else { return }

        notificationToken?.invalidate()

        let realm = AppRealm.open()
        results = realm.objects(Report.self)
            .filter("incident=%@ AND canonicalId=%@ AND filterPriority <> %@", incident, NSNull(), TriagePriority.transported.rawValue)
        if let text = commandHeader.searchField.text, !text.isEmpty {
            results = results?
                .filter("(pin CONTAINS[cd] %@) OR (patient.firstName CONTAINS[cd] %@) OR (patient.lastName CONTAINS[cd] %@)", text, text, text)
        }
        results = results?.sorted(by: [
            SortDescriptor(keyPath: "filterPriority"),
            SortDescriptor(keyPath: "pin")
        ])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
        refresh()
    }

    @objc func refresh() {
        guard let incident = incident else { return }
        AppRealm.getReports(incident: incident) { (_, _) in
        }
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Report>>) {
        switch changes {
        case .initial:
            decorateMap()
        case .update:
            decorateMap()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    func decorateMap() {
        mapView.clear()
        guard let results = results else { return }
        var target = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        var count = 0
        for report in results {
            if let latLng = report.patient?.latLng {
                let marker = GMSMarker()
                marker.position = latLng
                marker.title = "#\(report.pin ?? "")"
                marker.snippet = "\(report.patient?.fullName ?? "")\n\(report.patient?.ageString ?? "") \(report.patient?.genderString ?? "")"
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let priority = TriagePriority(rawValue: report.patient?.priority ?? TriagePriority.unknown.rawValue) {
                    marker.icon = priority.mapMarkerImage
                }
                marker.map = mapView
                target.latitude += latLng.latitude
                target.longitude += latLng.longitude
                count += 1
            }
        }
        if count > 0 {
            target.latitude /= Double(count)
            target.longitude /= Double(count)
            mapView.camera = GMSCameraPosition(target: target, zoom: 16)
        }
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        performQuery()
    }

    func formFieldShouldReturn(_ field: PRKit.FormField) -> Bool {
        field.resignFirstResponder()
        return false
    }
}
