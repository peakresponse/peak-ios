//
//  PatientView.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import AVFoundation
import UIKit

@objc protocol PortraitViewDelegate {
    @objc optional func patientView(_ patientView: PortraitView, didCapturePhoto fileURL: URL, withImage image: UIImage)
}

class PortraitViewCameraButton: UIButton {
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        return contentRect
    }
}

class PortraitView: UIView, CameraHelperDelegate {
    weak var imageView: RoundImageView!
    weak var captureButton: UIButton!
    weak var activityIndicatorView: UIActivityIndicatorView!

    var imageViewURL: String?

    weak var delegate: PortraitViewDelegate?

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
        let imageView = RoundImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leftAnchor.constraint(equalTo: leftAnchor),
            imageView.rightAnchor.constraint(equalTo: rightAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
        self.imageView = imageView

        let captureButton = UIButton(type: .custom)
        captureButton.alpha = 0
        captureButton.isUserInteractionEnabled = false
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.setImage(UIImage(named: "Camera")?.withRenderingMode(.alwaysTemplate), for: .normal)
        captureButton.tintColor = .mainGrey
        captureButton.isHidden = true
        captureButton.addTarget(self, action: #selector(capturePressed(_:)), for: .touchUpInside)
        addSubview(captureButton)
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            captureButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
        self.captureButton = captureButton

        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.tintColor = .mainGrey
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
        self.activityIndicatorView = activityIndicatorView
    }

    func configure(from patient: Patient) {
        imageViewURL = nil
        imageView.image = nil
        if let observation = patient as? PatientObservation {
            imageViewURL = observation.portraitFile
        }
        if imageViewURL == nil {
            imageViewURL = patient.portraitUrl
        }
        if let imageViewURL = imageViewURL {
            AppCache.cachedImage(from: imageViewURL) { [weak self] (image, _) in
                if let image = image {
                    DispatchQueue.main.async { [weak self] in
                        if imageViewURL == self?.imageViewURL {
                            self?.imageView.image = image
                        }
                    }
                }
            }
        } else {
            imageView.image = UIImage(named: "User")
            imageView.backgroundColor = .greyPeakBlue
        }
    }

    @objc func capturePressed(_ sender: Any) {
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
