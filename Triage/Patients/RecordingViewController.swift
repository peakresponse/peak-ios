//
//  RecordingViewController.swift
//  Triage
//
//  Created by Francis Li on 8/21/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit
import Accelerate
import TranscriptionKit

@objc protocol RecordingViewControllerDelegate {
    @objc optional func recordingViewController(_ vc: RecordingViewController, didRecognizeText text: String,
                                                fileId: String, transcriptId: String, metadata: [String: Any], isFinal: Bool)
    @objc optional func recordingViewController(_ vc: RecordingViewController, didFinishRecording fileId: String, fileURL: URL)
    @objc optional func recordingViewController(_ vc: RecordingViewController, didThrowError error: Error)
}

class RecordingViewController: UIViewController, TranscriberDelegate {
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var stopButton: RecordButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var spectrumStackView: UIStackView!
    @IBOutlet weak var observationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sheetView: UIView!

    weak var delegate: RecordingViewControllerDelegate?

    private var transcriber: Transcriber!
    private var barHeightConstraints: [NSLayoutConstraint] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        isModal = true

        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.layer.cornerRadius = 10

        for _ in 0..<26 {
            let barView = UIView()
            barView.translatesAutoresizingMaskIntoConstraints = false
            barView.backgroundColor = .white
            barView.layer.cornerRadius = 2
            spectrumStackView.addArrangedSubview(barView)
            let heightConstraint = barView.heightAnchor.constraint(equalToConstant: 8)
            barHeightConstraints.append(heightConstraint)
            NSLayoutConstraint.activate([
                barView.widthAnchor.constraint(equalToConstant: 6),
                heightConstraint
            ])
        }

        transcriber = Transcriber()
        if let awsCredentials = AppSettings.awsCredentials,
            let accessKey = awsCredentials["AccessKeyId"],
            let secretKey = awsCredentials["SecretAccessKey"],
            let sessionToken = awsCredentials["SessionToken"] {
            transcriber.recognizer = AWSRecognizer(accessKey: accessKey,
                                                   secretKey: secretKey,
                                                   sessionToken: sessionToken,
                                                   region: .USWest2)
        }
        transcriber.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startRecording()
    }

    func startRecording() {
        do {
            try transcriber.startRecording()
        } catch {
            delegate?.recordingViewController?(self, didThrowError: error)
        }
    }

    @IBAction func cancelPressed(_ sender: Any) {
        transcriber.stopRecording()
        dismissAnimated()
    }

    @IBAction func stopPressed(_ sender: Any) {
        transcriber.stopRecording()
        delegate?.recordingViewController?(self, didFinishRecording: transcriber.fileId, fileURL: transcriber.fileURL)
        stopButton.layer.opacity = 0
        activityIndicatorView.startAnimating()
        cancelButton.isHidden = true
    }

    // MARK: - TranscriberDelegate

    func transcriber(_ transcriber: Transcriber, didRecognizeText text: String, fileId: String, transcriptId: String,
                     metadata: [String: Any], isFinal: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.recordingViewController?(self, didRecognizeText: text, fileId: fileId, transcriptId: transcriptId,
                                                    metadata: metadata, isFinal: isFinal)
        }
    }

    func transcriber(_ transcriber: Transcriber, didRecord seconds: TimeInterval, formattedDuration duration: String) {
        timeLabel.text = duration
    }

    func transcriber(_ transcriber: Transcriber, didTransformBuffer data: [Float]) {
        // decimate the data into number of bars samples
        let filterLength = data.count / barHeightConstraints.count
        let filter = [Float](repeating: 16, count: filterLength)
        var output = [Float](repeating: 0, count: barHeightConstraints.count)
        vDSP_desamp(data, filterLength, filter, &output, vDSP_Length(output.count), vDSP_Length(filterLength))
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let barHeightConstraints = self.barHeightConstraints
            for (i, magnitude) in output.enumerated() {
                barHeightConstraints[i].constant = 4 + CGFloat(floor(min(1, magnitude) * 36))
            }
        }
    }

    func transcriberDidFinishRecognition(_ transcriber: Transcriber, withError error: Error?) {
        dismissAnimated()
    }

    func transcriber(_ transcriber: Transcriber, didRequestRecordAuthorization status: TranscriberAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if status == .granted {
                self.startRecording()
            } else {
                self.delegate?.recordingViewController?(self, didThrowError: TranscriberError.recordNotAuthorized)
            }
        }
    }

    func transcriber(_ transcriber: Transcriber, didRequestSpeechAuthorization status: TranscriberAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if status == .granted {
                self.startRecording()
            } else {
                self.delegate?.recordingViewController?(self, didThrowError: TranscriberError.speechRecognitionNotAuthorized)
            }
        }
    }
}
