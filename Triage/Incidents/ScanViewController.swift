//
//  ScanViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import AVFoundation
import PRKit
import RealmSwift
import UIKit

class ScanCameraView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if let sublayers = layer.sublayers {
            for layer in sublayers {
                layer.frame = bounds
            }
        }
    }
}

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, PRKit.FormFieldDelegate {
    @IBOutlet weak var cameraLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var pinField: PRKit.TextField!

    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    var incident: Incident?

    deinit {
        removeKeyboardListener()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addKeyboardListener()
        isModal = true

        let formInputAccessoryView = FormInputAccessoryView(rootView: view)
        pinField.inputAccessoryView = formInputAccessoryView

        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // re-enable camera
        if videoPreviewLayer != nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    override func didPresentAnimated() {
        super.didPresentAnimated()
        // disable camera, if running
        if videoPreviewLayer != nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }

    override func didDismissPresentation() {
        super.didDismissPresentation()
        // re-enable camera
        if videoPreviewLayer != nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // disable camera, if running
        if videoPreviewLayer != nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }

    @objc override func keyboardWillShow(_ notification: NSNotification) {
        if let pinFieldFrame = pinField.superview?.convert(pinField.frame, to: nil),
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            if keyboardFrame.minY < pinFieldFrame.maxY {
                let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
                UIView.animate(withDuration: duration) {
                    var bounds = self.view.bounds
                    bounds.origin.y = -floor(keyboardFrame.minY - pinFieldFrame.maxY) + 20
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
            cameraView.layer.addSublayer(videoPreviewLayer!)
            // Start video capture, ideally with ~2 megapixels of image data
            if captureSession.canSetSessionPreset(.hd1920x1080) {
                captureSession.sessionPreset = .hd1920x1080
            }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        } catch {
            print(error)
        }
    }

    @IBAction func didTap(_ sender: Any) {
        pinField.text = nil
        _ = pinField.resignFirstResponder()
    }

    func findPIN() {
        // hide keyboard
        _ = pinField.resignFirstResponder()
        // get input
        guard let pin = pinField.text else { return }
        let realm = AppRealm.open()
        guard let sceneId = AppSettings.sceneId else { return }
        let results = realm.objects(Report.self).filter("canonicalId=%@ AND pin=%@ AND scene.canonicalId=%@", NSNull(), pin, sceneId).sorted(byKeyPath: "createdAt", ascending: false)
        if results.count > 0 {
            presentReport(report: results[0])
        } else {
            presentNewReport(incident: incident, pin: pin)
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
            captureSession.stopRunning()
            pinField.text = pin
            findPIN()
        }
    }

    // MARK: - FormFieldDelegate

    func formFieldDidBeginEditing(_ field: PRKit.FormField) {
        captureSession.stopRunning()
    }

    func formFieldDidEndEditing(_ field: PRKit.FormField) {
        if !(pinField.text?.isEmpty ?? true) {
            findPIN()
        } else {
            captureSession.startRunning()
        }
    }

    // MARK: - ReportContainerViewControllerDelegate

    override func reportContainerViewControllerDidSave(_ vc: ReportContainerViewController) {
        dismissAnimated()
    }
}
