//
//  ScanViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import AVFoundation
import CoreLocation
import MLKitBarcodeScanning
import MLKitVision
import PRKit
internal import RealmSwift
import UIKit

class LicenseScanCameraView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if let sublayers = layer.sublayers {
            for layer in sublayers {
                layer.frame = bounds
            }
        }
    }
}

@objc protocol LicenseScanViewControllerDelegate {
    @objc optional func licenseScanViewController(_ vc: LicenseScanViewController, didScan license: BarcodeDriverLicense)
}

class LicenseScanViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var cameraLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!

    weak var delegate: LicenseScanViewControllerDelegate?

    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    var barcodeScanner: BarcodeScanner!

    var incident: Incident?

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraLabel.textColor = .text
        view.backgroundColor = .background

        isModal = true

        setupCamera()
    }

    func start() {
        // re-enable camera
        if videoPreviewLayer != nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
            MotionHelper.instance.startDeviceMotionUpdates()
        }
    }

    func stop() {
        // disable camera, if running
        if videoPreviewLayer != nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
            MotionHelper.instance.stopDeviceMotionUpdates()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        start()
    }

    override func didPresentAnimated() {
        super.didPresentAnimated()
        stop()
    }

    override func didDismissPresentation() {
        super.didDismissPresentation()
        start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stop()
    }

    private func setupCamera() {
        // Get the back-facing camera for capturing videos
        var zoomFactor: CGFloat = 1.0
        var captureDevice: AVCaptureDevice!
        captureDevice = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back)
        if captureDevice == nil {
            captureDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back)
            if captureDevice != nil {
                zoomFactor = 2.0
            }
        }
        if captureDevice == nil {
            captureDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        }
        if captureDevice == nil {
            captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
        if captureDevice == nil {
            captureDevice = AVCaptureDevice.default(for: .video)
        }
        guard captureDevice != nil else {
            print("Failed to get the camera device")
            return
        }
        // Create a barcode scanner.
        let barcodeOptions = BarcodeScannerOptions(formats: [BarcodeFormat.PDF417])
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
            if zoomFactor > 1.0 {
                do {
                    try captureDevice.lockForConfiguration()
                    captureDevice.videoZoomFactor = zoomFactor
                    captureDevice.unlockForConfiguration()
                } catch {
                    // no-op
                    print("Unable to set zoom factor", zoomFactor)
                }
            }
            start()
        } catch {
            print(error)
        }
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
        guard let inputImage = MLImage(sampleBuffer: sampleBuffer) else {
          print("Failed to create MLImage from sample buffer.")
          return
        }
        let orientation = imageOrientation(fromDevicePosition: .back)
        inputImage.orientation = orientation

        var barcodes: [Barcode] = []
        do {
            barcodes = try barcodeScanner.results(in: inputImage)
            if let barcode = barcodes.first, let license = barcode.driverLicense {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.licenseScanViewController?(self, didScan: license)
                    self.delegate = nil
                }
            }
        } catch let error {
            print("Failed to scan barcodes with error: \(error.localizedDescription).")
        }
    }
}
