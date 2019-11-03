//
//  ScanViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import AVFoundation
import UIKit

@objc protocol ScanViewControllerDelegate {
    @objc optional func scanViewControllerDidDismiss(_ vc: ScanViewController)
    @objc optional func scanViewController(_ vc: ScanViewController, didScan patient: Patient)
}

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, ObservationTableViewControllerDelegate, PinFieldDelegate {
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var pinField: PinField!
    @IBOutlet weak var pinFieldWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var pinFieldHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: ScanViewControllerDelegate?

    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //// set up pin field entry
        pinField.text = nil
        pinField.font = UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .regular)
        pinField.delegate = self
        let pinFieldSize = ("555555" as NSString).size(withAttributes: [
            .font: pinField.font as Any
        ])
        pinFieldWidthConstraint.constant = round(pinFieldSize.width) + 1
        pinFieldHeightConstraint.constant = pinFieldSize.height
        view.layoutIfNeeded()
        
        setupCamera()
    }
    
    private func setupCamera() {
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back)
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            // Set the input device on the capture session.
            captureSession.addInput(input)
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = cameraView.layer.bounds
            cameraView.layer.addSublayer(videoPreviewLayer!)
            // Start video capture.
            captureSession.startRunning()
        } catch {
            print(error)
        }
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        delegate?.scanViewControllerDidDismiss?(self)
    }

    @IBAction func didTap(_ sender: Any) {
        _ = pinField.resignFirstResponder()
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            if let pin = metadataObj.stringValue {
                pinField.text = pin
                pinField(pinField, didChange: pin)
            }
        }
    }
    
    // MARK: - PinFieldDelegate

    func pinFieldDidBeginEditing(_ field: PinField) {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.cameraView.alpha = 0
        }, completion: { [weak self] (finished) in
            self?.cameraView.isHidden = true
            self?.view.layoutIfNeeded()
        })
    }

    func pinFieldDidEndEditing(_ field: PinField) {
        cameraView.isHidden = false
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.cameraView.alpha = 1
        }, completion: { [weak self] (finished) in
            self?.view.layoutIfNeeded()
        })
    }
    
    func pinField(_ field: PinField, didChange pin: String) {
        if pin.count == 6 {
            captureSession.stopRunning()
            //// hide keyboard
            _ = field.resignFirstResponder()
            //// check if Patient record exists
            let realm = AppRealm.open()
            let results = realm.objects(Patient.self).filter("pin=%@", pin)
            if results.count > 0 {
                delegate?.scanViewController?(self, didScan: results[0])
            } else {
                let patient = Patient()
                patient.pin = pin
                if let navVC = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Observation") as? UINavigationController,
                    let vc = navVC.topViewController as? ObservationTableViewController {
                    vc.delegate = self
                    vc.patient = patient
                    present(navVC, animated: true, completion: nil)
                }
            }
            pinField.text = nil
        }
    }

    // MARK: - ObservationTableViewControllerDelegate
    
    func observationTableViewControllerDidDismiss(_ vc: ObservationTableViewController) {
        dismiss(animated: true) { [weak self] in
            if self?.videoPreviewLayer != nil {
                self?.captureSession.startRunning()
            }
        }
    }
    
    func observationTableViewController(_ vc: ObservationTableViewController, didSave observation: Observation) {
        //// Observations saved here are for new Patient records, so fetch the Patient record
        if let patientId = observation.patientId {
            AppRealm.getPatient(idOrPin: patientId) { (error) in
                DispatchQueue.main.async { [weak self] in
                    if let error = error {
                        self?.presentAlert(error: error)
                    }
                }
            }
        }
        dismiss(animated: true) { [weak self] in
            if self?.videoPreviewLayer != nil {
                self?.captureSession.startRunning()
            }
        }
    }
}
