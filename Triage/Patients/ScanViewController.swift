//
//  ScanViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import AVFoundation
import UIKit

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, ObservationViewControllerDelegate, UITextFieldDelegate {
    @IBOutlet weak var navigationBar: NavigationBar!
    @IBOutlet weak var cameraLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var pinFieldLabel: UILabel!
    @IBOutlet weak var pinField: UITextField!

    private var inputToolbar: UIToolbar!

    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    deinit {
        removeKeyboardListener()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addKeyboardListener()

        isModal = true

        inputToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
        inputToolbar.setItems([
            UIBarButtonItem(
                title: "InputAccessoryView.cancel".localized, style: .plain, target: self, action: #selector(inputCancelPressed)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(
                title: "InputAccessoryView.go".localized, style: .plain, target: self, action: #selector(inputSearchPressed))
        ], animated: false)

        // labels and fields
        cameraLabel.font = .copyMBold
        orLabel.font = .copyMBold
        pinFieldLabel.font = .copyMBold

        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // re-enable camera
        if videoPreviewLayer != nil {
            captureSession.startRunning()
        }
    }

    override func didPresentAnimated() {
        super.didPresentAnimated()
        // disable camera, if running
        if videoPreviewLayer != nil {
            captureSession.stopRunning()
        }
    }

    override func didDismissPresentation() {
        super.didDismissPresentation()
        // re-enable camera
        if videoPreviewLayer != nil {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // disable camera, if running
        if videoPreviewLayer != nil {
            captureSession.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = cameraView.bounds
    }

    @objc override func keyboardWillShow(_ notification: NSNotification) {
        if let pinFieldFrame = pinField.superview?.convert(pinField.frame, to: nil),
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            if keyboardFrame.minY < pinFieldFrame.maxY {
                let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
                UIView.animate(withDuration: duration) {
                    var bounds = self.view.bounds
                    bounds.origin.y = -floor(keyboardFrame.minY - pinFieldFrame.maxY)
                    self.view.bounds = bounds
                }
            }
        }
    }

    @objc override func keyboardWillHide(_ notification: NSNotification) {
        UIView.animate(withDuration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25) {
            var bounds = self.view.bounds
            bounds.origin.y = 0
            self.view.bounds = bounds
        }
    }

    private func setupCamera() {
        // Get the back-facing camera for capturing videos
        var captureDevice: AVCaptureDevice! = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
        if captureDevice == nil {
            captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
        guard captureDevice != nil else {
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
            captureMetadataOutput.metadataObjectTypes = [.code39, .code128, .qr]
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = cameraView.layer.bounds
            print(cameraView.frame, cameraView.layer.bounds)
            cameraView.layer.addSublayer(videoPreviewLayer!)
            // Start video capture.
            captureSession.startRunning()
        } catch {
            print(error)
        }
    }

    @IBAction func didTap(_ sender: Any) {
        inputCancelPressed()
    }

    override var inputAccessoryView: UIView? {
        return inputToolbar
    }

    @objc func inputCancelPressed() {
        _ = pinField.resignFirstResponder()
    }

    @objc func inputSearchPressed() {
        // hide keyboard
        _ = pinField.resignFirstResponder()
        // get input
        guard let pin = pinField.text else { return }
        // check if Patient record exists
        let realm = AppRealm.open()
        let results = realm.objects(Patient.self).filter("sceneId=%@ AND pin=%@ AND canonicalId=NULL", AppSettings.sceneId ?? "", pin)
        var vc: UIViewController?
        if results.count > 0 {
            vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Patient")
            if let vc = vc as? PatientViewController {
                vc.patient = results[0]
            }
        } else {
            let patient = Patient()
            patient.new()
            patient.sceneId = AppSettings.sceneId
            patient.pin = pin
            patient.createdAt = Date()
            vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(withIdentifier: "Observation")
            if let vc = vc as? ObservationViewController {
                vc.delegate = self
                vc.patient = patient
            }
        }
        if let vc = vc {
            // present modally
            presentAnimated(vc)
        }
        // clear pinfield
        pinField.text = nil
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            return
        }

        // Get the metadata object.
        if let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
           let pin = metadataObj.stringValue {
            pinField.text = pin
            inputSearchPressed()
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        captureSession.stopRunning()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        captureSession.startRunning()
    }

    // MARK: - ObservationViewControllerDelegate

    func observationViewControllerDidCancel(_ vc: ObservationViewController) {
        dismissAnimated()
    }

    func observationViewControllerDidSave(_ vc: ObservationViewController) {
        dismissAnimated()
    }
}
