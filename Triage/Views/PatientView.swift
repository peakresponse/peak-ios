//
//  PatientView.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import AVFoundation
import UIKit

@objc protocol PatientViewDelegate {
    @objc optional func patientView(_ patientView: PatientView, didCapturePhoto fileURL: URL, withImage image: UIImage)
}

class PatientViewCameraButton: UIButton {
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        return contentRect
    }
}

class PatientView: UIView, CameraHelperDelegate {
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var imageView: RoundImageView!
    var imageViewURL: String?
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    weak var delegate: PatientViewDelegate?
    
    var cameraHelper: CameraHelper?
    
    var isEditing: Bool {
        get { return !captureButton.isHidden }
        set { captureButton.isHidden = !newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        loadNib()
        captureButton.layer.opacity = 0.25
    }
    
    func configure(from patient: Patient) {
        imageView.image = nil
        imageViewURL = patient.portraitUrl
        if let imageViewURL = imageViewURL {
            AppCache.cachedImage(from: imageViewURL) { [weak self] (image, error) in
                if let error = error {
                    print(error)
                } else if let image = image {
                    DispatchQueue.main.async { [weak self] in
                        if imageViewURL == self?.imageViewURL  {
                            self?.imageView.image = image
                        }
                    }
                }
            }
        }
    }

    @IBAction func capturePressed(_ sender: Any) {
        guard let cameraHelper = cameraHelper else { return }
        if cameraHelper.isReady {
            if cameraHelper.isRunning {
                imageView.image = nil
                captureButton.isHidden = true
                activityIndicatorView.startAnimating()
                cameraHelper.videoPreviewLayer?.removeFromSuperlayer()
                cameraHelper.capture()
            } else if let videoPreviewLayer = cameraHelper.videoPreviewLayer {
                videoPreviewLayer.frame = imageView.layer.bounds
                imageView.layer.addSublayer(videoPreviewLayer)
                cameraHelper.delegate = self
                cameraHelper.startRunning()
            }
        } else {
            captureButton.isHidden = true
            activityIndicatorView.startAnimating()
            DispatchQueue.global().async { [weak self] in
                // wait for setup to complete
                self?.cameraHelper?.setupSemaphore.wait()
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicatorView.stopAnimating()
                    self?.captureButton.isHidden = false
                    self?.capturePressed(sender)
                }
            }
        }
    }

    // MARK: - CameraHelperDelegate
    
    func cameraHelper(_ helper: CameraHelper, didCapturePhoto fileURL: URL, withImage image: UIImage) {
        self.imageView.image = image
        self.activityIndicatorView.stopAnimating()
        self.captureButton.isHidden = false
        self.delegate?.patientView?(self, didCapturePhoto: fileURL, withImage: image)
    }
}
