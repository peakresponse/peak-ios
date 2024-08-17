//
//  LatLngControl.swift
//  Triage
//
//  Created by Francis Li on 6/5/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import CoreLocation
import PRKit
import UIKit

protocol LatLngControlDelegate: AnyObject {
    func latLngControlDidCaptureLocation(_ control: LatLngControl)
    func latLngControlMapPressed(_ control: LatLngControl)
}

class LatLngControl: UIStackView, LocationHelperDelegate {
    weak var label: UILabel!
    weak var captureButton: PRKit.Button!
    weak var mapButton: PRKit.Button!

    weak var delegate: LatLngControlDelegate?

    var isEditing = true {
        didSet { didUpdateEditing() }
    }
    var isCapturing = false
    var location: CLLocationCoordinate2D? {
        didSet { didUpdateLocation() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        spacing = 8
        axis = .vertical

        let label = UILabel()
        label.font = .body14Bold
        label.textColor = .base500
        addArrangedSubview(label)
        self.label = label

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 16
        addArrangedSubview(row)

        let captureButton = PRKit.Button()
        captureButton.size = .small
        captureButton.style = .secondary
        captureButton.setImage(UIImage(named: "Update24px", in: PRKitBundle.instance, compatibleWith: nil), for: .normal)
        captureButton.tintColor = .brandPrimary500
        captureButton.setTitle("Button.captureLocation".localized, for: .normal)
        captureButton.addTarget(self, action: #selector(capturePressed), for: .touchUpInside)
        captureButton.isLayoutVerticalAllowed = false
        row.addArrangedSubview(captureButton)
        self.captureButton = captureButton

        let mapButton = PRKit.Button()
        mapButton.size = .small
        mapButton.style = .secondary
        mapButton.setImage(UIImage(named: "Pin24px", in: PRKitBundle.instance, compatibleWith: nil), for: .normal)
        mapButton.tintColor = .brandPrimary500
        mapButton.setTitle("Button.map".localized, for: .normal)
        mapButton.addTarget(self, action: #selector(mapPressed), for: .touchUpInside)
        row.addArrangedSubview(mapButton)
        self.mapButton = mapButton
    }

    @objc func capturePressed() {
        location = LocationHelper.instance.latestLocation?.coordinate
        if location == nil {
            isCapturing = true
            LocationHelper.instance.delegate = self
            LocationHelper.instance.requestLocation()
            label.text = "LatLngControl.capturingLocation".localized
        } else {
            delegate?.latLngControlDidCaptureLocation(self)
        }
        updateButtons()
    }

    @objc func mapPressed() {
        delegate?.latLngControlMapPressed(self)
    }

    func didUpdateEditing() {
        guard !isCapturing || !isEditing else { return }
        updateButtons()
    }

    func didUpdateLocation() {
        if let location = location {
            label.text = "\(String(format: "%.6f", location.latitude)), \(String(format: "%.6f", location.longitude))"
            mapButton.isEnabled = true
        } else {
            label.text = nil
            mapButton.isEnabled = false
        }
    }

    func updateButtons() {
        captureButton.isEnabled = isEditing && !isCapturing
        captureButton.setTitle(location != nil ? "Button.updateLocation".localized : "Button.captureLocation".localized, for: .normal)
        mapButton.isEnabled = !isCapturing && location != nil
    }

    // MARK: - LocationHelperDelegate

    func locationHelper(_ helper: LocationHelper, didUpdateLocations locations: [CLLocation]) {
        if isEditing && isCapturing {
            if let location = locations.last {
                isCapturing = false
                self.location = location.coordinate
                delegate?.latLngControlDidCaptureLocation(self)
            }
        }
        updateButtons()
    }

    func locationHelper(_ helper: LocationHelper, didFailWithError error: Error) {
        isCapturing = false
        label.text = error.localizedDescription
        updateButtons()
    }
}
