//
//  RecordingViewController.swift
//  Triage
//
//  Created by Francis Li on 8/21/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit
import Accelerate
import Speech

@objc protocol RecordingViewControllerDelegate {
    @objc optional func recordingViewController(_ vc: RecordingViewController, didRecognizeText text: String,
                                                sourceId: String, metadata: [String: Any], isFinal: Bool)
    @objc optional func recordingViewController(_ vc: RecordingViewController, didFinishRecording fileURL: URL)
    @objc optional func recordingViewController(_ vc: RecordingViewController, didThrowError error: Error)
}

class RecordingViewController: UIViewController, AudioHelperDelgate {
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var stopButton: RecordButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var spectrumStackView: UIStackView!
    @IBOutlet weak var observationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sheetView: UIView!

    weak var delegate: RecordingViewControllerDelegate?

    private var audioHelper: AudioHelper!
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

        audioHelper = AudioHelper()
        audioHelper.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startRecording()
    }

    func startRecording() {
        do {
            try audioHelper.startRecording()
        } catch {
            delegate?.recordingViewController?(self, didThrowError: error)
        }
    }

    @IBAction func cancelPressed(_ sender: Any) {
        audioHelper.stopRecording()
        dismissAnimated()
    }

    @IBAction func stopPressed(_ sender: Any) {
        audioHelper.stopRecording()
        delegate?.recordingViewController?(self, didFinishRecording: audioHelper.fileURL)
        stopButton.layer.opacity = 0
        activityIndicatorView.startAnimating()
        cancelButton.isHidden = true
    }

    // MARK: - AudioHelperDelegate

    func audioHelper(_ audioHelper: AudioHelper, didFinishPlaying successfully: Bool) {

    }

    func audioHelper(_ audioHelper: AudioHelper, didPlay seconds: TimeInterval, formattedDuration duration: String) {

    }

    func audioHelper(_ audioHelper: AudioHelper, didRecognizeText text: String,
                     sourceId: String, metadata: [String: Any], isFinal: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.recordingViewController?(self, didRecognizeText: text,
                                                    sourceId: sourceId, metadata: metadata, isFinal: isFinal)
        }
    }

    func audioHelper(_ audioHelper: AudioHelper, didRecord seconds: TimeInterval, formattedDuration duration: String) {
        timeLabel.text = duration
    }

    func audioHelper(_ audioHelper: AudioHelper, didTransformBuffer input: [Float]) {
        // decimate the data into number of bars samples
        let filterLength = input.count / barHeightConstraints.count
        let filter = [Float](repeating: 16, count: filterLength)
        var output = [Float](repeating: 0, count: barHeightConstraints.count)
        vDSP_desamp(input, filterLength, filter, &output, vDSP_Length(output.count), vDSP_Length(filterLength))
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let barHeightConstraints = self.barHeightConstraints
            for (i, magnitude) in output.enumerated() {
                barHeightConstraints[i].constant = 4 + CGFloat(floor(min(1, magnitude) * 36))
            }
        }
    }

    func audioHelperDidFinishRecognition(_ audioHelper: AudioHelper) {
        dismissAnimated()
    }

    func audioHelper(_ audioHelper: AudioHelper, didRequestRecordAuthorization status: AVAudioSession.RecordPermission) {
        if status == .granted {
            startRecording()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.recordingViewController?(self, didThrowError: AudioHelperError.recordNotAuthorized)
            }
        }
    }

    func audioHelper(_ audioHelper: AudioHelper, didRequestSpeechAuthorization status: SFSpeechRecognizerAuthorizationStatus) {
        if status == .authorized {
            startRecording()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.recordingViewController?(self, didThrowError: AudioHelperError.speechRecognitionNotAuthorized)
            }
        }
    }
}
