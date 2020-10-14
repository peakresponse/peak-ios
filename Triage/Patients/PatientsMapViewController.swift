//
//  PatientsMapViewController.swift
//  Triage
//
//  Created by Francis Li on 11/15/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import GoogleMaps
import MapKit
import RealmSwift
import UIKit

class PatientAnnotation: MKPointAnnotation {
    var patient: Patient!
}

class PatientsMapViewController: UIViewController, UISearchBarDelegate, GMSMapViewDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    private var searchBarShouldBeginEditing = true
    @IBOutlet weak var mapContainerView: UIView!
    weak var mapView: GMSMapView!

    weak var selectedPinMarker: GMSMarker?
    weak var selectedPinInfoView: ScenePinInfoView?

    var scene: Scene!
    var sceneNotificationToken: NotificationToken?

    var patients: Results<Patient>?
    var patientsNotificationToken: NotificationToken?

    var pins: Results<ScenePin>?
    var pinsNotificationToken: NotificationToken?

    // MARK: -

    deinit {
        sceneNotificationToken?.invalidate()
        patientsNotificationToken?.invalidate()
        pinsNotificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // get a reference to the Scene and listen for changes
        guard let sceneId = AppSettings.sceneId else { return }
        scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId)
        guard scene != nil else { return }
        sceneNotificationToken = scene?.observe { [weak self] (_) in
            self?.refresh()
        }

        // set up Google Map
        var mapView: GMSMapView
        if let target = scene.latLng {
            let camera = GMSCameraPosition(target: target, zoom: 16)
            mapView = GMSMapView(frame: mapContainerView.bounds, camera: camera)
        } else {
            mapView = GMSMapView(frame: mapContainerView.bounds)
        }
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapContainerView.addSubview(mapView)
        self.mapView = mapView

        // set up Realm query and observer
        performQuery()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // trigger additional refresh
        refresh()
    }

    private func performQuery() {
        patientsNotificationToken?.invalidate()
        let realm = AppRealm.open()
        var predicates: [NSPredicate] = []
        var predicate: NSPredicate
        if let sceneId = AppSettings.sceneId {
            predicates.append(NSPredicate(format: "sceneId=%@", sceneId))
        }
        if let text = searchBar.text, !text.isEmpty {
            predicates.append(NSPredicate(format: "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@", text, text))
        }
        predicate = predicates.count == 1 ? predicates[0] : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        patients = realm.objects(Patient.self).filter(predicate)
        patientsNotificationToken = patients?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }

        predicates = []
        predicates.append(NSPredicate(format: "deletedAt=NULL"))
        if let sceneId = AppSettings.sceneId {
            predicates.append(NSPredicate(format: "scene.id=%@", sceneId))
        }
        if let text = searchBar.text, !text.isEmpty {
            predicates.append(NSPredicate(format: "type CONTAINS[cd] %@ OR name CONTAINS[cd] %@ OR desc CONTAINS[cd] %@", text, text))
        }
        predicate = predicates.count == 1 ? predicates[0] : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        pins = realm.objects(ScenePin.self).filter(predicate)
        pinsNotificationToken = pins?.observe { [weak self] (changes) in
            switch changes {
            case .initial:
                self?.addAnnotations()
            case .update:
                self?.addAnnotations()
            case .error(let error):
                self?.presentAlert(error: error)
            }
        }
    }

    private func createMarker(for patient: Patient) -> GMSMarker? {
        if let position = patient.latLng, let priority = patient.priority.value, priority < 5 {
            let marker = GMSMarker(position: position)
            marker.userData = patient
            marker.title = String(format: "Patient.pin".localized, patient.pin ?? "")
            marker.icon = GMSMarker.priorityMarkerImages[priority]
            return marker
        }
        return nil
    }

    private func createMarker(for pin: ScenePin) -> GMSMarker? {
        if let position = pin.latLng, let type = ScenePinType(rawValue: pin.type ?? "") {
            let marker = GMSMarker(position: position)
            marker.userData = pin
            marker.icon = type.markerImage.scaledBy(0.666)
            return marker
        }
        return nil
    }

    private func addAnnotations() {
        // for now, just brute force remove and re-add annotations
        mapView.clear()
        var bounds = GMSCoordinateBounds()
        if let patients = patients {
            for patient in patients {
                if let marker = createMarker(for: patient) {
                    marker.map = mapView
                    bounds = bounds.includingCoordinate(marker.position)
                }
            }
        }
        if let pins = pins {
            for pin in pins {
                if let marker = createMarker(for: pin) {
                    marker.map = mapView
                    bounds = bounds.includingCoordinate(marker.position)
                }
            }
        }
        if bounds.isValid {
            mapView.setMinZoom(1, maxZoom: 18)
            let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
            mapView.animate(with: update)
            mapView.setMinZoom(1, maxZoom: 20)
        }
    }

    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Patient>>) {
        switch changes {
        case .initial:
            addAnnotations()
        case .update:
            addAnnotations()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    @objc func refresh() {
        if let sceneId = AppSettings.sceneId {
            AppRealm.getPatients(sceneId: sceneId) { [weak self] (error) in
                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        if let error = error as? ApiClientError, error == .unauthorized {
                            self?.presentLogin()
                        } else {
                            self?.presentAlert(error: error)
                        }
                    }
                }
            }
        }
    }

    @IBAction func logoutPressed(_ sender: Any) {
        logout()
    }

    private func navigate(to patient: Patient) {
        let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Patient")
        if let vc = vc as? PatientViewController {
            vc.patient = patient
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "NavigationBar.done".localized, style: .done, target: self, action: #selector(dismissAnimated))
            presentAnimated(vc)
        }
    }

    private func deselectPin() -> Bool {
        var result = false
        if let selectedPinMarker = selectedPinMarker,
           let selectedPin = selectedPinMarker.userData as? ScenePin,
           let selectedType = ScenePinType(rawValue: selectedPin.type ?? "") {
            selectedPinMarker.icon = selectedType.markerImage.scaledBy(0.666)
            var result = true
        }
        selectedPinMarker = nil
        selectedPinInfoView?.removeFromSuperview()
        selectedPinInfoView = nil
        return result
    }

    // MARK: - GMSMapViewDelegate

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let patient = marker.userData as? Patient {
            navigate(to: patient)
            return true
        } else if let pin = marker.userData as? ScenePin, let type = ScenePinType(rawValue: pin.type ?? "") {
            _ = deselectPin()

            marker.icon = type.markerImage
            selectedPinMarker = marker

            let pinInfoView = ScenePinInfoView()
            pinInfoView.translatesAutoresizingMaskIntoConstraints = false
            pinInfoView.configure(from: pin)
            view.addSubview(pinInfoView)
            NSLayoutConstraint.activate([
                pinInfoView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
                pinInfoView.leftAnchor.constraint(equalTo: view.leftAnchor),
                pinInfoView.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
            self.selectedPinInfoView = pinInfoView
        }
        return false
    }

    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        if !deselectPin() {
            // TODO start new pin flow at this location
        }
    }

    // MARK: - UISearchBarDelegate

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchBar.isFirstResponder {
            searchBarShouldBeginEditing = false
        }
        _ = deselectPin()
        performQuery()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        let result = searchBarShouldBeginEditing
        searchBarShouldBeginEditing = true
        return result
    }
}
