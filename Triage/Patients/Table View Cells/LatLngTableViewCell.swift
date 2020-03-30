//
//  LatLngTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import CoreLocation
import UIKit

@objc protocol LatLngTableViewCellDelegate {
    @objc optional func latLngTableViewCellDidClear(_ cell: LatLngTableViewCell)
    @objc optional func latLngTableViewCell(_ cell: LatLngTableViewCell, didCapture lat: String, lng: String)
}

class LatLngTableViewCell: PatientTableViewCell, PatientTableViewCellBackground, CLLocationManagerDelegate, UITextFieldDelegate {
    @IBOutlet weak var customBackgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var disclosureImageView: UIImageView!
    
    weak var delegate: LatLngTableViewCellDelegate?
    let locationManager = CLLocationManager()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        captureButton.isHidden = true
        valueField.delegate = self
        valueField.inputView = UIView(frame: .zero)
        
        locationManager.requestWhenInUseAuthorization()
    }

    override func configure(from patient: Patient) {
        if let lat = patient.lat, let lng = patient.lng {
            let text = "\(lat), \(lng)".trimmingCharacters(in: .whitespacesAndNewlines)
            if text != "," {
                valueField.text = text
                captureButton.isHidden = true
                disclosureImageView.isHidden = false
                selectionStyle = .default
                return
            }
        }
        valueField.text = nil
        captureButton.isHidden = !isEditing
        disclosureImageView.isHidden = true
        selectionStyle = .none
    }
    
    @IBAction func capturePressed(_ sender: Any) {
        captureLocation()
    }

    func captureLocation() {
        captureButton.isHidden = true
        activityIndicatorView.startAnimating()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        activityIndicatorView.stopAnimating()
        if let location = locations.last {
            let lat = String(format: "%.6f", location.coordinate.latitude)
            let lng = String(format: "%.6", location.coordinate.longitude)
            valueField.text = "\(lat), \(lng)"
            delegate?.latLngTableViewCell?(self, didCapture: lat, lng: lng)
            disclosureImageView.isHidden = false
            selectionStyle = .default
        } else {
            captureButton.isHidden = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        valueField.text = error.localizedDescription
    }

    // MARK: - UITableViewCell

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        valueField.isUserInteractionEnabled = editing
        valueField.clearButtonMode = editing ? .always : .never
        captureButton.isHidden = valueField.text != "" || !editing
    }
    
    // MARK: - UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        delegate?.latLngTableViewCellDidClear?(self)
        captureButton.isHidden = false
        disclosureImageView.isHidden = true
        selectionStyle = .none
        return true
    }
}
