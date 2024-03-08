//
//  ScanViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import AVFoundation
import MLKitBarcodeScanning
import MLKitVision
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

@objc protocol ScanViewControllerDelegate {
    @objc optional func scanViewController(_ vc: ScanViewController, didScan pin: String, report: Report?)
}

class ScanViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, PRKit.FormFieldDelegate {
    @IBOutlet weak var cameraLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var pinField: PRKit.TextField!

    weak var delegate: ScanViewControllerDelegate?

    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    var barcodeScanner: BarcodeScanner!
    var scannedValues: [String] = []

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
        // Create a barcode scanner.
        let barcodeOptions = BarcodeScannerOptions(formats: [BarcodeFormat.code39, BarcodeFormat.code128])
        barcodeScanner = BarcodeScanner.barcodeScanner(options: barcodeOptions)
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            // Set the input device on the capture session.
            captureSession.addInput(input)
            // Output video frames for MLKit analysis
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
            output.alwaysDiscardsLateVideoFrames = true
            let outputQueue = DispatchQueue(label: "net.peakresponse.Triage.VideoDataOutputQueue")
            output.setSampleBufferDelegate(self, queue: outputQueue)
            captureSession.addOutput(output)
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
        pinField.clearPressed()
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
        if let delegate = delegate {
            delegate.scanViewController?(self, didScan: pin, report: results.first)
        } else {
            if results.count > 0 {
                presentReport(report: results[0])
            } else {
                presentNewReport(incident: incident, pin: pin)
            }
        }
        // clear pinfield
        pinField.clearPressed()
    }

    func currentUIOrientation() -> UIDeviceOrientation {
        let deviceOrientation = { () -> UIDeviceOrientation in
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:
                return .landscapeRight
            case .landscapeRight:
                return .landscapeLeft
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .portrait, .unknown:
                return .portrait
            @unknown default:
                fatalError()
            }
        }
        guard Thread.isMainThread else {
            var currentOrientation: UIDeviceOrientation = .portrait
            DispatchQueue.main.sync {
                currentOrientation = deviceOrientation()
            }
            return currentOrientation
        }
        return deviceOrientation()
    }

    func imageOrientation(fromDevicePosition devicePosition: AVCaptureDevice.Position = .back) -> UIImage.Orientation {
        var deviceOrientation = UIDevice.current.orientation
        if deviceOrientation == .faceDown || deviceOrientation == .faceUp || deviceOrientation == .unknown {
            deviceOrientation = currentUIOrientation()
        }
        switch deviceOrientation {
        case .portrait:
          return devicePosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
          return devicePosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
          return devicePosition == .front ? .rightMirrored : .left
        case .landscapeRight:
          return devicePosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
          return .up
        @unknown default:
          fatalError()
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
          print("Failed to get image buffer from sample buffer.")
          return
        }

        let visionImage = VisionImage(buffer: sampleBuffer)
        let orientation = imageOrientation(fromDevicePosition: .back)
        visionImage.orientation = orientation

        guard let inputImage = MLImage(sampleBuffer: sampleBuffer) else {
          print("Failed to create MLImage from sample buffer.")
          return
        }
        inputImage.orientation = orientation

        var barcodes: [Barcode] = []
        do {
            barcodes = try barcodeScanner.results(in: inputImage)
            if let pin = barcodes.first?.displayValue {
                if scannedValues.count > 0 {
                    if let prevPin = scannedValues.first, pin == prevPin {
                        scannedValues.append(pin)
                    } else {
                        scannedValues = [pin]
                    }
                    if scannedValues.count >= 3 {
                        scannedValues = []
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.captureSession.stopRunning()
                            self.pinField.attributeValue = pin as NSObject
                            self.findPIN()
                        }
                    }
                } else {
                    scannedValues.append(pin)
                }
            }
        } catch let error {
            print("Failed to scan barcodes with error: \(error.localizedDescription).")
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
