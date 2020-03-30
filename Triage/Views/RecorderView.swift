//
//  RecorderView.swift
//  Triage
//
//  Created by Francis Li on 3/23/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit
import Speech
import Accelerate

@objc protocol RecorderViewDelegate {
    @objc optional func recorderViewDidShow(_ view: RecorderView)
    @objc optional func recorderViewDidDismiss(_ view: RecorderView)
    @objc optional func recorderView(_ view: RecorderView, didRecognizeText text: String)
    @objc optional func recorderView(_ view: RecorderView, didFinishRecording fileURL: URL)
    @objc optional func recorderView(_ view: RecorderView, didThrowError error: Error)
}

class RecorderView: UIView, AudioHelperDelgate {
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var sheetView: UIView!
    @IBOutlet weak var sheetViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sheetViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var observationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var spectrumStackView: UIStackView!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    weak var delegate: RecorderViewDelegate?

    private var audioHelper: AudioHelper!
    private var barHeightConstraints: [NSLayoutConstraint] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        loadNib()
        
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.layer.cornerRadius = 15
        sheetView.addShadow(withOffset: CGSize(width: 0, height: -2), radius: 10, color: .black, opacity: 0.25)

        for _ in 0..<32 {
            let barView = UIView()
            barView.translatesAutoresizingMaskIntoConstraints = false
            barView.backgroundColor = .white
            barView.layer.cornerRadius = 2
            spectrumStackView.addArrangedSubview(barView)
            let heightConstraint = barView.heightAnchor.constraint(equalToConstant: 4)
            barHeightConstraints.append(heightConstraint)
            NSLayoutConstraint.activate([
                barView.widthAnchor.constraint(equalToConstant: 4),
                heightConstraint
            ])
        }
        
        let cornerRadius = stopButton.frame.width / 2
        stopButton.setBackgroundImage(UIImage.resizableImage(withColor: .natBlue, cornerRadius: cornerRadius), for: .normal)
        stopButton.setBackgroundImage(UIImage.resizableImage(withColor: UIColor.natBlue.colorWithBrightnessMultiplier(multiplier: 0.4), cornerRadius: cornerRadius), for: .highlighted)
        stopButton.layer.cornerRadius = cornerRadius
        stopButton.layer.borderColor = UIColor.white.cgColor
        stopButton.layer.borderWidth = 3
        stopButton.addShadow(withOffset: CGSize(width: 0, height: 4), radius: 4, color: .black, opacity: 0.25)

        audioHelper = AudioHelper()
        audioHelper.delegate = self
    }

    @IBAction func stopPressed(_ sender: Any) {
        audioHelper.stopRecording()
        delegate?.recorderView?(self, didFinishRecording: audioHelper.fileURL)
        stopButton.layer.opacity = 0
        activityIndicatorView.startAnimating()
    }

    func show() {
        overlayView.layer.opacity = 0
        sheetViewBottomConstraint.constant = sheetViewHeightConstraint.constant
        layoutIfNeeded()
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            self?.overlayView.layer.opacity = 0.8
            self?.sheetViewBottomConstraint.constant = 0
            self?.layoutIfNeeded()
        }, completion: { [weak self] (finished) in
            guard let self = self else { return }
            self.delegate?.recorderViewDidShow?(self)
            /// start recording!
            self.startRecording()
        })
    }

    func startRecording() {
        do {
            try self.audioHelper.startRecording()
        } catch {
            self.delegate?.recorderView?(self, didThrowError: error)
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            self?.overlayView.layer.opacity = 0
            self?.sheetViewBottomConstraint.constant = self?.sheetViewHeightConstraint?.constant ?? 280
            self?.layoutIfNeeded()
        }, completion: { [weak self] (finished) in
            guard let self = self else { return }
            self.removeFromSuperview()
            self.delegate?.recorderViewDidDismiss?(self)
        })
    }

    // MARK: - AudioHelperDelegate

    func audioHelper(_ audioHelper: AudioHelper, didFinishPlaying successfully: Bool) {
        
    }

    func audioHelper(_ audioHelper: AudioHelper, didPlay seconds: TimeInterval, formattedDuration duration: String) {
        
    }

    func audioHelper(_ audioHelper: AudioHelper, didRecognizeText text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.recorderView?(self, didRecognizeText: text)
        }
    }

    func audioHelper(_ audioHelper: AudioHelper, didRecord seconds: TimeInterval, formattedDuration duration: String) {
        timeLabel.text = duration
    }

    func audioHelper(_ audioHelper: AudioHelper, didTransformBuffer input: [Float]) {
        /// decimate the data into number of bars samples
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
        hide()
    }

    func audioHelper(_ audioHelper: AudioHelper, didRequestRecordAuthorization status: AVAudioSession.RecordPermission) {
        if status == .granted {
            startRecording()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.recorderView?(self, didThrowError: AudioHelperError.recordNotAuthorized)
            }
        }
    }
    
    func audioHelper(_ audioHelper: AudioHelper, didRequestSpeechAuthorization status: SFSpeechRecognizerAuthorizationStatus) {
        if status == .authorized {
            startRecording()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.recorderView?(self, didThrowError: AudioHelperError.speechRecognitionNotAuthorized)
            }
        }
    }
}
