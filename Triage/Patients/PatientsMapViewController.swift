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

class PatientsMapViewController: UIViewController, UISearchBarDelegate, MKMapViewDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    private var searchBarShouldBeginEditing = true
    @IBOutlet weak var mapView: MKMapView!

    var notificationToken: NotificationToken?
    var results: Results<Patient>?

    // MARK: -
    
    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Patient")
        
        // set up Realm query and observer
        performQuery()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // trigger additional refresh
        refresh()
    }
    
    private func performQuery() {
        notificationToken?.invalidate()
        let realm = AppRealm.open()
        var predicates: [NSPredicate] = []
        if let sceneId = AppSettings.sceneId {
            predicates.append(NSPredicate(format: "sceneId=%@", sceneId))
        }
        if let text = searchBar.text, !text.isEmpty {
            predicates.append(NSPredicate(format: "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@", text, text))
        }
        let predicate = predicates.count == 1 ? predicates[0] : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        results = realm.objects(Patient.self).filter(predicate)
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
    }

    private func createAnnotation(for patient: Patient) -> MKAnnotation? {
        if let lat = Double(patient.lat ?? ""), let lng = Double(patient.lng ?? "") {
            let location = CLLocation(latitude: lat, longitude: lng)
            let annotation = PatientAnnotation()
            annotation.patient = patient
            annotation.coordinate = location.coordinate
            annotation.title = patient.fullName
            annotation.subtitle = patient.pin
            return annotation
        }
        return nil
    }

    private func addAnnotations() {
        // for now, just brute force remove and re-add annotations
        mapView.removeAnnotations(mapView.annotations)
        if let results = results {
            for patient in results {
                if let annotation = createAnnotation(for: patient) {
                    mapView.addAnnotation(annotation)
                }
            }
            mapView.showAnnotations(mapView.annotations, animated: true)
        }
    }
    
    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Patient>>) {
        switch changes {
        case .initial(_):
            addAnnotations()
        case .update(_, _, _, _):
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
        if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Patient") as? PatientViewController {
            vc.patient = patient
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized, style: .done, target: self, action: #selector(dismissAnimated))
            presentAnimated(vc)
        }
    }
    
    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: "Patient", for: annotation)
        if let view = view as? MKMarkerAnnotationView, let annotation = annotation as? PatientAnnotation {
            view.markerTintColor = annotation.patient.priorityColor
            view.glyphTintColor = annotation.patient.priorityLabelColor
            view.clusteringIdentifier = "Patient"
            if let priority = annotation.patient.priority.value {
                if priority < 2 {
                    view.displayPriority = .defaultHigh
                } else {
                    view.displayPriority = .defaultLow
                }
            } else {
                view.displayPriority = .required
            }
        }
        return view
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? PatientAnnotation {
            navigate(to: annotation.patient)
        } else if let cluster = view.annotation as? MKClusterAnnotation {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let annotations = cluster.memberAnnotations.sorted { (annotationA, annotationB) -> Bool in
                if let annotationA = annotationA as? PatientAnnotation, let annotationB = annotationB as? PatientAnnotation {
                    return annotationA.patient.priority.value ?? 0 > annotationB.patient.priority.value ?? 0
                }
                return false
            }
            for annotation in annotations {
                if let annotation = annotation as? PatientAnnotation, let patient = annotation.patient {
                    let action = UIAlertAction(title: patient.fullName, style: .default, handler: { [weak self] (action) in
                        self?.navigate(to: patient)
                    })
                    action.setValue(patient.priorityColor, forKey: "titleTextColor")
                    alert.addAction(action);
                }
            }
            alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
            presentAnimated(alert)
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
