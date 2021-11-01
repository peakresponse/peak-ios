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

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
class PatientsMapViewController: UIViewController, UISearchBarDelegate, GMSMapViewDelegate, NewScenePinViewDelegate,
                                 ScenePinInfoViewDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    private var searchBarShouldBeginEditing = true
    @IBOutlet weak var mapContainerView: UIView!
    weak var mapView: GMSMapView!
    var isMapViewInitialzed = false

    var selectedPinMarker: GMSMarker?
    weak var selectedPinInfoView: ScenePinInfoView?

    weak var newPin: ScenePin?
    weak var newPinMarker: GMSMarker?
    weak var newPinView: NewScenePinView?

    var isMGS = false

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
        isMGS = AppSettings.userId == scene.incidentCommanderId
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
        var predicates: [NSPredicate] = [
            NSPredicate(format: "canonicalId == NULL")
        ]
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
        if let position = patient.latLng, let priority = patient.filterPriority, priority < Priority.transported.rawValue {
            let marker = GMSMarker(position: position)
            marker.userData = patient
            marker.title = String(format: "Patient.pin".localized, patient.pin ?? "")
            marker.icon = GMSMarker.priorityMarkerImages[priority]
            return marker
        }
        return nil
    }

    private func createMarker(for pin: ScenePin) -> GMSMarker? {
        if let position = pin.latLng {
            let marker = GMSMarker(position: position)
            marker.userData = pin
            marker.icon = (ScenePinType(rawValue: pin.type ?? "")?.markerImage ?? UIImage(named: "MapMarkerNew"))?.scaledBy(0.666)
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
        if bounds.isValid && !isMapViewInitialzed {
            mapView.setMinZoom(1, maxZoom: 18)
            let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
            mapView.animate(with: update)
            mapView.setMinZoom(1, maxZoom: 20)
            isMapViewInitialzed = true
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
        isMGS = AppSettings.userId == scene.incidentCommanderId
        AppRealm.getPatients(sceneId: scene.id) { [weak self] (error) in
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
        guard newPin == nil else { return false }
        var result = false
        if let selectedPinMarker = selectedPinMarker,
           let selectedPin = selectedPinMarker.userData as? ScenePin,
           let selectedType = ScenePinType(rawValue: selectedPin.type ?? "") {
            selectedPinMarker.icon = selectedType.markerImage.scaledBy(0.666)
            result = true
        }
        selectedPinMarker = nil
        selectedPinInfoView?.removeFromSuperview()
        selectedPinInfoView = nil
        return result
    }

    // MARK: - GMSMapViewDelegate

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard newPin == nil else { return true }
        if let patient = marker.userData as? Patient {
            navigate(to: patient)
            return true
        } else if let pin = marker.userData as? ScenePin, let type = ScenePinType(rawValue: pin.type ?? "") {
            _ = deselectPin()

            marker.icon = type.markerImage
            selectedPinMarker = marker

            let pinInfoView = ScenePinInfoView()
            pinInfoView.translatesAutoresizingMaskIntoConstraints = false
            pinInfoView.configure(from: pin, isMGS: isMGS)
            pinInfoView.delegate = self
            view.addSubview(pinInfoView)
            NSLayoutConstraint.activate([
                pinInfoView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
                pinInfoView.leftAnchor.constraint(equalTo: view.leftAnchor),
                pinInfoView.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
            self.selectedPinInfoView = pinInfoView
            return true
        }
        return false
    }

    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        if !deselectPin() {
            if let newPin = newPin {
                newPin.latLng = coordinate
                newPinMarker?.position = coordinate
            } else {
                let newPin = ScenePin()
                newPin.latLng = coordinate
                self.newPin = newPin

                let newPinMarker = createMarker(for: newPin)
                newPinMarker?.icon = UIImage(named: "MapMarkerNew")
                newPinMarker?.map = mapView
                self.newPinMarker = newPinMarker

                let newPinView = NewScenePinView()
                newPinView.translatesAutoresizingMaskIntoConstraints = false
                newPinView.delegate = self
                newPinView.newPin = newPin
                view.addSubview(newPinView)
                NSLayoutConstraint.activate([
                    newPinView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
                    newPinView.leftAnchor.constraint(equalTo: view.leftAnchor),
                    newPinView.rightAnchor.constraint(equalTo: view.rightAnchor)
                ])
                self.newPinView = newPinView
            }
        }
    }

    // MARK: - NewScenePinViewDelegate

    func newScenePinView(_ view: NewScenePinView, didSelect pinType: ScenePinType) {
        guard let newPin = newPin else { return }
        newPin.type = pinType.rawValue
        newPinMarker?.map = nil
        let newPinMarker = createMarker(for: newPin)
        newPinMarker?.icon = pinType.markerImage
        newPinMarker?.map = mapView
        self.newPinMarker = newPinMarker
    }

    func newScenePinView(_ view: NewScenePinView, didChangeName name: String) {
        guard let newPin = newPin else { return }
        newPin.name = name
    }

    func newScenePinView(_ view: NewScenePinView, didChangeDesc desc: String) {
        guard let newPin = newPin else { return }
        newPin.desc = desc
    }

    func newScenePinViewDidCancel(_ view: NewScenePinView) {
        newPin = nil
        newPinMarker?.map = nil
        newPinMarker = nil
        newPinView?.removeFromSuperview()
        newPinView = nil
    }

    func newScenePinViewDidSave(_ view: NewScenePinView) {
        guard let newPin = newPin else { return }
        AppRealm.createOrUpdateScenePin(sceneId: scene.id, pin: newPin)
        self.newScenePinViewDidCancel(view)
    }

    // MARK: - ScenePinInfoViewDelegate

    func scenePinInfoViewDidEdit(_ view: ScenePinInfoView) {
        guard let pin = selectedPinMarker?.userData as? ScenePin else { return }
        // clone the selected pin for editing
        let newPin = ScenePin(clone: pin)
        newPin.prevPinId = pin.id
        self.newPin = newPin

        // create a marker for the cloned pin
        let newPinMarker = createMarker(for: newPin)
        newPinMarker?.icon = ScenePinType(rawValue: newPin.type ?? "")?.markerImage
        newPinMarker?.map = mapView
        self.newPinMarker = newPinMarker

        // remove the source pin marker from the map while editing
        selectedPinMarker?.map = nil
    }

    func scenePinInfoViewDidCancel(_ view: ScenePinInfoView) {
        // discard the cloned pin
        newPinMarker?.map = nil
        newPinMarker = nil
        newPin = nil

        // add the original source pin back to map
        selectedPinMarker?.map = mapView

        // discard any edited changes in the info view
        guard let pin = selectedPinMarker?.userData as? ScenePin else { return }
        selectedPinInfoView?.configure(from: pin, isMGS: isMGS)
    }

    func scenePinInfoViewDidDelete(_ view: ScenePinInfoView) {
        guard let pin = selectedPinMarker?.userData as? ScenePin else { return }
        let vc = AlertViewController()
        vc.alertTitle = "PatientsMapViewController.deletePin.title".localized
        vc.alertMessage = "PatientsMapViewController.deletePin.message".localized
        vc.addAlertAction(title: "Button.cancel".localized, style: .cancel, handler: nil)
        vc.addAlertAction(title: "Button.delete".localized, style: .default) { [weak self] (_) in
            AppRealm.removeScenePin(pin)
            self?.selectedPinInfoView?.removeFromSuperview()
            self?.selectedPinMarker = nil
            self?.dismissAnimated()
        }
        presentAnimated(vc)
    }

    func scenePinInfoView(_ view: ScenePinInfoView, didChangeDesc desc: String) {
        guard let newPin = newPin else { return }
        newPin.desc = desc
    }

    func scenePinInfoViewDidSave(_ view: ScenePinInfoView) {
        guard let newPin = newPin else { return }
        AppRealm.createOrUpdateScenePin(sceneId: scene.id, pin: newPin)
        // discard the cloned pin
        newPinMarker?.map = nil
        newPinMarker = nil
        self.newPin = nil
        // as well as the original selected pin and view
        selectedPinInfoView?.removeFromSuperview()
        selectedPinMarker = nil
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
