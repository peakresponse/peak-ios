//
//  CameraHelper.swift
//  Triage
//
//  Created by Francis Li on 11/14/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import AVFoundation
import UIKit

@objc protocol CameraHelperDelegate {
    @objc optional func cameraHelper(_ helper: CameraHelper, didCapturePhoto fileURL: URL, withImage image: UIImage)
}

class CameraHelper: NSObject, AVCapturePhotoCaptureDelegate {
    var setupSemaphore = DispatchSemaphore(value: 0)
    var captureSession: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    weak var delegate: CameraHelperDelegate?
    
    var isReady: Bool {
        return videoPreviewLayer != nil
    }

    var isRunning: Bool {
        return captureSession?.isRunning ?? false
    }
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        DispatchQueue.global().async { [weak self] in
            // setup the camera
            let captureSession = AVCaptureSession()
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
            guard let captureDevice = deviceDiscoverySession.devices.first else {
                print("Failed to get the camera device")
                return
            }
            do {
                captureSession.beginConfiguration()
                // Get an instance of the AVCaptureDeviceInput class using the previous device object.
                let input = try AVCaptureDeviceInput(device: captureDevice)
                // Set the input device on the capture session.
                captureSession.addInput(input)
                // configure photo output
                let photoOutput = AVCapturePhotoOutput()
                photoOutput.isHighResolutionCaptureEnabled = true
                photoOutput.isLivePhotoCaptureEnabled = false
                guard captureSession.canAddOutput(photoOutput) else { return }
                captureSession.sessionPreset = .photo
                captureSession.addOutput(photoOutput)
                self?.photoOutput = photoOutput
                // Start video capture.
                captureSession.commitConfiguration()
                self?.captureSession = captureSession
                // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
                let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                self?.videoPreviewLayer = videoPreviewLayer
                // notify waiting threads, if any
                self?.setupSemaphore.signal()
            } catch {
                print(error)
            }
        }
    }

    func startRunning() {
        captureSession?.startRunning()
    }
    
    func capture() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = .auto
        photoOutput?.capturePhoto(with: photoSettings, delegate: self)
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        captureSession?.stopRunning()
        if let error = error {
            DispatchQueue.main.async {
                print(error)
            }
        } else {
            DispatchQueue.global().async { [weak self] in
                if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
                    let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let tempFileURL = tempDirURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
                    do {
                        try data.write(to: tempFileURL, options: [.atomic])
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.delegate?.cameraHelper?(self, didCapturePhoto: tempFileURL, withImage: image)
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}
