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

class ScanViewController: BaseViewController, AVCaptureVideoDataOutputSampleBufferDelegate, LocationHelperDelegate, PRKit.FormFieldDelegate {
    weak var commandHeader: CommandHeader!
    @IBOutlet weak var cameraLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var pinField: PRKit.TextField!

    weak var delegate: ScanViewControllerDelegate?

    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    var barcodeScanner: BarcodeScanner!
    var scannedValues: [String] = []

    var incident: Incident?

    override init() {
        super.init()
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        removeKeyboardListener()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background

        let commandHeader = CommandHeader()
        commandHeader.translatesAutoresizingMaskIntoConstraints = false
        commandHeader.preservesSuperviewLayoutMargins = true
        headerView.addSubview(commandHeader)
        NSLayoutConstraint.activate([
            commandHeader.topAnchor.constraint(equalTo: headerView.topAnchor),
            commandHeader.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            commandHeader.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            commandHeader.contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            commandHeader.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            headerView.bottomAnchor.constraint(equalTo: commandHeader.bottomAnchor)
        ])
        self.commandHeader = commandHeader

        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "Button.done".localized, style: .done,
                                                          target: self, action: #selector(dismissAnimated))

        let cameraLabel = UILabel()
        cameraLabel.translatesAutoresizingMaskIntoConstraints = false
        cameraLabel.text = "ScanViewController.scanPatientTag".localized
        cameraLabel.textColor = .text
        cameraLabel.font = .h4SemiBold
        contentView.addSubview(cameraLabel)
        NSLayoutConstraint.activate([
            cameraLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            cameraLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        self.cameraLabel = cameraLabel

        let cameraView = UIView()
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        cameraView.backgroundColor = .black
        contentView.addSubview(cameraView)
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: cameraLabel.bottomAnchor, constant: 7),
            cameraView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            cameraView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor, multiplier: 1.0)
        ])
        self.cameraView = cameraView

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "ScanViewController.or".localized
        label.textColor = .base500
        label.font = .h4SemiBold
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: cameraView.bottomAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])

        var hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentView.addSubview(hr)
        NSLayoutConstraint.activate([
            hr.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            hr.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            hr.rightAnchor.constraint(equalTo: label.leftAnchor, constant: -16)
        ])

        hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentView.addSubview(hr)
        NSLayoutConstraint.activate([
            hr.leftAnchor.constraint(equalTo: label.leftAnchor, constant: 16),
            hr.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            hr.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])

        let pinField = PRKit.TextField()
        pinField.translatesAutoresizingMaskIntoConstraints = false
        pinField.labelText = "ScanViewController.enterTagCode".localized
        pinField.attributeType = .integer
        pinField.delegate = self
        contentView.addSubview(pinField)
        NSLayoutConstraint.activate([
            pinField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
            pinField.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            pinField.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])
        self.pinField = pinField

        addKeyboardListener()

        let formInputAccessoryView = FormInputAccessoryView(rootView: view)
        pinField.inputAccessoryView = formInputAccessoryView

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

    @IBAction func didTap(_ sender: Any) {
        pinField.clearPressed()
        _ = pinField.resignFirstResponder()
    }

    func findPIN(fromScan: Bool) {
        // hide keyboard
        _ = pinField.resignFirstResponder()
        // get input
        guard let pin = pinField.text else { return }
        let realm = AppRealm.open()
        guard let sceneId = AppSettings.sceneId else { return }
        let results = realm.objects(Report.self).filter("canonicalId=%@ AND deletedAt=%@ AND pin=%@ AND scene.canonicalId=%@", NSNull(), NSNull(), pin, sceneId).sorted(byKeyPath: "createdAt", ascending: false)
        if let delegate = delegate {
            delegate.scanViewController?(self, didScan: pin, report: results.first)
        } else {
            if let report = results.first {
                presentReport(report: report)
                if fromScan {
                    updateReportLocation(report: report)
                }
            } else {
                presentNewReport(incident: incident, pin: pin)
            }
        }
        // clear pinfield
        pinField.clearPressed()
    }

    func updateReportLocation(report: Report) {
        if let location = LocationHelper.instance.latestLocation {
            let newReport = Report(clone: report)
            newReport.patient?.latLng = location.coordinate
            AppRealm.saveReport(report: newReport)
        } else {
            let reportId = report.id
            LocationHelper.instance.requestLocation { [weak self] (locations, _) in
                guard self != nil else { return }
                if let location = locations?.last {
                    let realm = AppRealm.open()
                    if let report = realm.object(ofType: Report.self, forPrimaryKey: reportId) {
                        let newReport = Report(clone: report)
                        newReport.patient?.latLng = location.coordinate
                        AppRealm.saveReport(report: newReport)
                    }
                }
            }
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
            if let pin = barcodes.first?.displayValue {
                if let magnitude = MotionHelper.instance.deviceMotion?.userAcceleration.magnitude, magnitude >= 0.1 {
                    scannedValues = []
                } else if scannedValues.count > 0 {
                    if let prevPin = scannedValues.first, pin == prevPin {
                        scannedValues.append(pin)
                    } else {
                        scannedValues = [pin]
                    }
                    if scannedValues.count >= 5 {
                        scannedValues = []
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.stop()
                            self.pinField.attributeValue = pin as NSObject
                            self.findPIN(fromScan: true)
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
        stop()
    }

    func formFieldDidEndEditing(_ field: PRKit.FormField) {
        if !(pinField.text?.isEmpty ?? true) {
            findPIN(fromScan: false)
        } else {
            start()
        }
    }

    // MARK: - ReportContainerViewControllerDelegate

    override func reportContainerViewControllerDidSave(_ vc: ReportContainerViewController) {
        dismissAnimated()
    }
}
