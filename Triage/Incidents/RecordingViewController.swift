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
import TranscriptionKitAWS

@objc protocol RecordingViewControllerDelegate {
    @objc optional func recordingViewController(_ vc: RecordingViewController, didRecognizeText text: String,
                                                fileId: String, transcriptId: String, metadata: [String: Any], isFinal: Bool)
    @objc optional func recordingViewController(_ vc: RecordingViewController, didFinishRecording fileId: String, fileURL: URL,
                                                duration: TimeInterval, formattedDuration: String)
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

        sheetView.backgroundColor = .primaryButtonNormal
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
                                                   region: "us-west-2")
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
        stopButton.layer.opacity = 0
        activityIndicatorView.startAnimating()
    }

    // MARK: - TranscriberDelegate

    func transcriberDidPlay(_ transcriber: TranscriptionKit.Transcriber, seconds: TimeInterval) {
    }

    func transcriberDidFinishPlaying(_ transcriber: TranscriptionKit.Transcriber, successfully: Bool, error: (any Error)?) {
    }

    func transcriberDidFailToRecord(_ transcriber: TranscriptionKit.Transcriber, error: any Error) {
        delegate?.recordingViewController?(self, didThrowError: error)
    }

    func transcriberDidRequestRecordAuthorization(_ transcriber: TranscriptionKit.Transcriber,
                                                  status: TranscriptionKit.TranscriberAuthorizationStatus) {
        if status == .granted {
            startRecording()
        } else {
            delegate?.recordingViewController?(self, didThrowError: TranscriberError.recordNotAuthorized)
        }
    }

    func transcriberDidRecord(_ transcriber: TranscriptionKit.Transcriber, seconds: TimeInterval, data: [Float]) {
        timeLabel.text = seconds.asTimeIntervalString()
        // decimate the data into number of bars samples
        let barCount = barHeightConstraints.count
        Task.detached {
            let filterLength = data.count / barCount
            let filter = [Float](repeating: 16, count: filterLength)
            var output = [Float](repeating: 0, count: barCount)
            vDSP_desamp(data, filterLength, filter, &output, vDSP_Length(output.count), vDSP_Length(filterLength))
            Task { @MainActor in
                let barHeightConstraints = self.barHeightConstraints
                for (i, magnitude) in output.enumerated() {
                    barHeightConstraints[i].constant = 4 + CGFloat(floor(min(1, magnitude) * 36))
                }
            }
        }
    }

    func transcriberDidFinishRecording(_ transcriber: TranscriptionKit.Transcriber, duration seconds: TimeInterval) {

    }

    func transcriberDidRequestSpeechAuthorization(_ transcriber: TranscriptionKit.Transcriber,
                                                  status: TranscriptionKit.TranscriberAuthorizationStatus) {
        if status == .granted {
            startRecording()
        } else {
            delegate?.recordingViewController?(self, didThrowError: TranscriberError.speechRecognitionNotAuthorized)
        }
    }

    func transcriberDidRecognize(_ transcriber: TranscriptionKit.Transcriber, text: String,
                                 fileId: String, transcriptId: String, metadata: [String: Any], isFinal: Bool) {
        delegate?.recordingViewController?(self, didRecognizeText: text, fileId: fileId, transcriptId: transcriptId,
                                           metadata: metadata, isFinal: isFinal)
    }

    func transcriberDidFinishRecognition(_ transcriber: Transcriber, error: Error?) {
        delegate?.recordingViewController?(self, didFinishRecording: transcriber.fileId, fileURL: transcriber.fileURL,
                                           duration: transcriber.recordingLength,
                                           formattedDuration: transcriber.recordingLength.asTimeIntervalString())
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
}
