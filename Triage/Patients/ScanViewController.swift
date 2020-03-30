//
//  ScanViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import AVFoundation
import UIKit

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, ObservationTableViewControllerDelegate, PinFieldDelegate {
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var pinField: PinField!
    @IBOutlet weak var pinFieldWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var pinFieldHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pinFieldLabel: UILabel!

    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up pin field entry
        pinField.text = nil
        pinField.font = UIFont(name: "NunitoSans-Regular", size: 48)
        pinField.delegate = self
        let pinFieldSize = pinField.sizeThatFits(CGSize.zero)
        pinFieldWidthConstraint.constant = pinFieldSize.width
        pinFieldHeightConstraint.constant = pinFieldSize.height
        view.layoutIfNeeded()
        
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let defaultNotificationCenter = NotificationCenter.default
        defaultNotificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        defaultNotificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func didPresentAnimated() {
        super.didPresentAnimated()
        /// disable camera, if running
        if videoPreviewLayer != nil {
            captureSession.stopRunning()
        }
    }
    
    override func didDismissPresentation() {
        super.didDismissPresentation()
        /// re-enable camera
        if videoPreviewLayer != nil {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let pinFieldFrame = pinFieldLabel.superview?.convert(pinFieldLabel.frame, to: nil),
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            if keyboardFrame.minY < pinFieldFrame.maxY {
                UIView.animate(withDuration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25) {
                    var frame = self.view.frame
                    frame.origin.y = floor(keyboardFrame.minY - pinFieldFrame.maxY)
                    self.view.frame = frame
                }
            }
        }
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        UIView.animate(withDuration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25) {
            var frame = self.view.frame
            frame.origin.y = 0
            self.view.frame = frame
        }
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
    
    @IBAction func logoutPressed(_ sender: Any) {
        logout()
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
        captureSession.stopRunning()
    }

    func pinFieldDidEndEditing(_ field: PinField) {
        captureSession.startRunning()
    }
    
    func pinField(_ field: PinField, didChange pin: String) {
        if pin.count == 6 {
            captureSession.stopRunning()
            /// hide keyboard
            _ = field.resignFirstResponder()
            /// check if Patient record exists
            let realm = AppRealm.open()
            let results = realm.objects(Patient.self).filter("pin=%@", pin)
            var navVC: UINavigationController?
            if results.count > 0 {
                navVC = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Patient") as? UINavigationController
                if let vc = navVC?.topViewController as? PatientTableViewController {
                    vc.patient = results[0]
                    vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("DONE", comment: ""), style: .done, target: self, action: #selector(dismissAnimated))
                }
            } else {
                let observation = Observation()
                observation.pin = pin
                navVC = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Observation") as? UINavigationController
                if let vc = navVC?.topViewController as? ObservationTableViewController {
                    vc.delegate = self
                    vc.patient = observation
                    vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("CANCEL", comment: ""), style: .done, target: self, action: #selector(dismissAnimated))
                }
            }
            if let navVC = navVC {
                /// present modally
                presentAnimated(navVC)
            }
            /// clear pinfield
            pinField.text = nil
        }
    }
    
    // MARK: - ObservationTableViewControllerDelegate
    
    func observationTableViewController(_ vc: ObservationTableViewController, didSave observation: Observation) {
        /// Observations saved here are for new Patient records, so fetch the Patient record
        if let patientId = observation.patientId {
            AppRealm.getPatient(idOrPin: patientId) { (error) in
                DispatchQueue.main.async { [weak self] in
                    if let error = error {
                        self?.presentAlert(error: error)
                    }
                }
            }
        }
        dismissAnimated()
    }
}
