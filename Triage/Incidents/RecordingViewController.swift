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
    weak var activityIndicatorView: UIActivityIndicatorView!
    weak var stopButton: RecordButton!
    weak var cancelButton: UIButton!
    weak var spectrumStackView: UIStackView!
    weak var observationLabel: UILabel!
    weak var timeLabel: UILabel!
    weak var sheetView: UIView!

    weak var delegate: RecordingViewControllerDelegate?

    private var transcriber: Transcriber!
    private var barHeightConstraints: [NSLayoutConstraint] = []

    init() {
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .coverVertical
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        let sheetView = UIView()
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        sheetView.backgroundColor = .primaryButtonNormal
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.layer.cornerRadius = 10
        view.addSubview(sheetView)
        NSLayoutConstraint.activate([
            sheetView.leftAnchor.constraint(equalTo: view.leftAnchor),
            sheetView.rightAnchor.constraint(equalTo: view.rightAnchor),
            sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.sheetView = sheetView

        let stopButton = RecordButton()
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.recordState = .stopAndSave
        stopButton.addTarget(self, action: #selector(stopPressed(_:)), for: .touchUpInside)
        sheetView.addSubview(stopButton)
        NSLayoutConstraint.activate([
            stopButton.bottomAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.bottomAnchor, constant: -22),
            stopButton.leftAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.leftAnchor, constant: 22),
            stopButton.rightAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.rightAnchor, constant: -22)
        ])
        self.stopButton = stopButton

        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.color = .white
        activityIndicatorView.hidesWhenStopped = true
        sheetView.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: stopButton.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: stopButton.centerYAnchor)
        ])
        self.activityIndicatorView = activityIndicatorView

        let spectrumStackView = UIStackView()
        spectrumStackView.translatesAutoresizingMaskIntoConstraints = false
        spectrumStackView.axis = .horizontal
        spectrumStackView.alignment = .bottom
        spectrumStackView.distribution = .equalSpacing
        spectrumStackView.spacing = 0
        sheetView.addSubview(spectrumStackView)
        NSLayoutConstraint.activate([
            spectrumStackView.heightAnchor.constraint(equalToConstant: 62),
            spectrumStackView.bottomAnchor.constraint(equalTo: stopButton.topAnchor, constant: -22),
            spectrumStackView.leftAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.leftAnchor, constant: 38),
            spectrumStackView.rightAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.rightAnchor, constant: -38)
        ])
        self.spectrumStackView = spectrumStackView

        let timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .h3SemiBold
        timeLabel.textColor = .white
        timeLabel.text = "00:00:00"
        sheetView.addSubview(timeLabel)
        NSLayoutConstraint.activate([
            timeLabel.bottomAnchor.constraint(equalTo: spectrumStackView.topAnchor, constant: -45),
            timeLabel.leftAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.leftAnchor, constant: 38),
            timeLabel.rightAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.rightAnchor, constant: -38)
        ])
        self.timeLabel = timeLabel

        let observationLabel = UILabel()
        observationLabel.translatesAutoresizingMaskIntoConstraints = false
        observationLabel.font = .h4SemiBold
        observationLabel.textColor = .white
        observationLabel.text = "RecordingViewController.observationLabel".localized
        sheetView.addSubview(observationLabel)
        NSLayoutConstraint.activate([
            observationLabel.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 14),
            observationLabel.leftAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.leftAnchor, constant: 38),
            observationLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor)
        ])
        self.observationLabel = observationLabel

        let cancelButton = UIButton()
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Button.cancel".localized, for: .normal)
        cancelButton.titleLabel?.font = .body14Bold
        cancelButton.titleLabel?.textColor = .white
        cancelButton.addTarget(self, action: #selector(cancelPressed(_:)), for: .touchUpInside)
        sheetView.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.rightAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.rightAnchor, constant: -22),
            cancelButton.centerYAnchor.constraint(equalTo: observationLabel.centerYAnchor)
        ])
        self.cancelButton = cancelButton

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

    @objc func cancelPressed(_ sender: Any) {
        transcriber.stopRecording()
        dismissAnimated()
    }

    @objc func stopPressed(_ sender: Any) {
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
