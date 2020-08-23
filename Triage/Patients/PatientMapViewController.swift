//
//  PatientMapViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import MapKit
import UIKit


class PatientMapViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var coordinateLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var patient: Patient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.cornerRadius = 5
        containerView.addShadow(withOffset: CGSize(width: 7, height: 7), radius: 50, color: .black, opacity: 0.4)

        headerView.layer.cornerRadius = 5
        headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        locationLabel.font = .copyMBold
        locationLabel.text = patient.location
        coordinateLabel.font = .copyXSRegular
        coordinateLabel.text = patient.latLngString
        
        mapView.layer.cornerRadius = 5
        mapView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        // Do any additional setup after loading the view.
        if let lat = Double(patient.lat ?? ""), let lng = Double(patient.lng ?? "") {
            let location = CLLocation(latitude: lat, longitude: lng)
            let regionRadius: CLLocationDistance = 1000
            let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                      latitudinalMeters: regionRadius,
                                                      longitudinalMeters: regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            mapView.addAnnotation(annotation)
        }
    }
}
