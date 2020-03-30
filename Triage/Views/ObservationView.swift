//
//  ObservationView.swift
//  Triage
//
//  Created by Francis Li on 3/29/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@objc protocol ObservationViewDelegate {
    @objc optional func observationView(_ observationView: ObservationView, didThrowError error: Error)
}

class ObservationView: UIView, AudioHelperDelgate {        
    static func heightForText(_ text: String, width: CGFloat) -> CGFloat {
        let font = UIFont(name: "NunitoSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        let text = text as NSString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        let rect = text.boundingRect(with: CGSize(width: width - 30 /* left and right margins */, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [
            .font: font,
            .paragraphStyle: paragraphStyle
        ], context: nil)
        return round(rect.height) + 16 /* top and bottom margins */ + 24 /* First row label height and bottom margin */
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timestampSeparatorLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var durationSeparatorLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var textView: UITextView!
    
    weak var delegate: ObservationViewDelegate?
    var audioHelper: AudioHelper?
    
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
        backgroundColor = .clear
        textView.contentInset = .zero
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
    }

    func configure(from patient: Patient) {
        titleLabel.text = NSLocalizedString("Observation", comment: "")
        timestampSeparatorLabel.isHidden = true
        timestampLabel.isHidden = true
        if let timestamp = patient.updatedAt?.asLocalizedTime() {
            timestampSeparatorLabel.isHidden = false
            timestampLabel.isHidden = false
            timestampLabel.text = timestamp
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        textView.attributedText = NSAttributedString(string: patient.text ?? "", attributes: [
            .font: textView.font ?? UIFont.systemFont(ofSize: 14),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textView.textColor ?? UIColor.gray4
        ])
        durationSeparatorLabel.isHidden = true
        durationLabel.isHidden = true
        playButton.isHidden = true
        if let audioUrl = patient.audioUrl {
            activityIndicatorView.startAnimating()
            AppCache.cachedFile(from: audioUrl) { [weak self] (url, error) in
                guard let self = self else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicatorView.stopAnimating()
                }
                if let error = error {
                    self.delegate?.observationView?(self, didThrowError: error)
                } else if let url = url {
                    if self.audioHelper == nil {
                        self.audioHelper = AudioHelper()
                    }
                    if let audioHelper = self.audioHelper {
                        audioHelper.delegate = self
                        audioHelper.fileURL = url
                        do {
                            try audioHelper.prepareToPlay()
                            DispatchQueue.main.async { [weak self] in
                                self?.playButton.isHidden = false
                                self?.playButton.setImage(UIImage(named: "Play"), for: .normal)
                                self?.durationLabel.isHidden = false
                                self?.durationSeparatorLabel.isHidden = false
                                self?.durationLabel.text = audioHelper.recordingLengthFormatted
                            }
                        } catch {
                            self.delegate?.observationView?(self, didThrowError: error)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func playPressed(_ sender: Any) {
        guard let audioHelper = audioHelper else { return }
        if audioHelper.isPlaying {
            audioHelper.stopPressed()
            playButton.setImage(UIImage(named: "Play"), for: .normal)
            durationLabel.text = audioHelper.recordingLengthFormatted
        } else {
            do {
                try audioHelper.playPressed()
                playButton.setImage(UIImage(named: "Stop"), for: .normal)
                durationLabel.text = "00:00:00"
            } catch {
                delegate?.observationView?(self, didThrowError: error)
            }
        }
    }
        
    // MARK: - AudioHelperDelegate

    func audioHelper(_ audioHelper: AudioHelper, didFinishPlaying successfully: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.playButton.setImage(UIImage(named: "Play"), for: .normal)
            self?.durationLabel.text = audioHelper.recordingLengthFormatted
        }
    }

    func audioHelper(_ audioHelper: AudioHelper, didPlay seconds: TimeInterval, formattedDuration duration: String) {
        DispatchQueue.main.async { [weak self] in
            if self?.audioHelper?.isPlaying ?? false {
                self?.durationLabel.text = duration
            }
        }
    }
}
