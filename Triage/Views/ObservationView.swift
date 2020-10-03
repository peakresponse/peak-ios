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
        let font = UIFont.copySBold
        let text = text as NSString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        let rect = text.boundingRect(with: CGSize(width: width - 20 /* left and right margins */, height: .greatestFiniteMagnitude),
                                     options: .usesLineFragmentOrigin, attributes: [
                                        .font: font,
                                        .paragraphStyle: paragraphStyle
                                    ], context: nil)
        return max(font.lineHeight, round(rect.height)) +
            18 /* top and bottom margins */ + 40 /* First row label height and bottom margin */
    }

    let playButton = UIButton(type: .custom)
    let activityIndicatorView = UIActivityIndicatorView()
    let titleLabel = UILabel()
    var titleLabelLeftConstraint: NSLayoutConstraint!
    var titleLabelPlayButtonConstraint: NSLayoutConstraint!
    let durationLabel = UILabel()
    let durationSeparatorLabel = UILabel()
    let timestampLabel = UILabel()
    var timestampLabelTitleLabelConstraint: NSLayoutConstraint!
    var timestampLabelDurationLabelConstraint: NSLayoutConstraint!
    let textView = UITextView()

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

    // swiftlint:disable:next function_body_length
    private func commonInit() {
        backgroundColor = .white
        addShadow(withOffset: CGSize(width: 0, height: 2), radius: 3, color: .black, opacity: 0.15)

        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setBackgroundImage(.resizableImage(withColor: .peakBlue, cornerRadius: 16), for: .normal)
        playButton.setBackgroundImage(.resizableImage(withColor: .darkPeakBlue, cornerRadius: 16), for: .highlighted)
        playButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        playButton.tintColor = .white
        playButton.addTarget(self, action: #selector(playPressed(_:)), for: .touchUpInside)
        addSubview(playButton)
        NSLayoutConstraint.activate([
            playButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            playButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            playButton.widthAnchor.constraint(equalToConstant: 32),
            playButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: playButton.centerYAnchor)
        ])

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .copyXSBold
        titleLabel.textColor = .lowPriorityGrey
        addSubview(titleLabel)
        titleLabelLeftConstraint = titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10)
        titleLabelPlayButtonConstraint = titleLabel.leftAnchor.constraint(equalTo: playButton.rightAnchor, constant: 8)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8)
        ])

        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = .copySRegular
        durationLabel.textColor = .peakBlue
        addSubview(durationLabel)
        NSLayoutConstraint.activate([
            durationLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
            durationLabel.bottomAnchor.constraint(equalTo: playButton.bottomAnchor)
        ])

        durationSeparatorLabel.translatesAutoresizingMaskIntoConstraints = false
        durationSeparatorLabel.font = .copySRegular
        durationSeparatorLabel.textColor = .peakBlue
        durationSeparatorLabel.text = "  |  "
        addSubview(durationSeparatorLabel)
        NSLayoutConstraint.activate([
            durationSeparatorLabel.leftAnchor.constraint(equalTo: durationLabel.rightAnchor),
            durationSeparatorLabel.bottomAnchor.constraint(equalTo: durationLabel.bottomAnchor)
        ])

        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.font = .copySRegular
        timestampLabel.textColor = .peakBlue
        addSubview(timestampLabel)
        timestampLabelTitleLabelConstraint = timestampLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor)
        timestampLabelDurationLabelConstraint = timestampLabel.leftAnchor.constraint(equalTo: durationSeparatorLabel.rightAnchor)
        NSLayoutConstraint.activate([
            timestampLabel.bottomAnchor.constraint(equalTo: playButton.bottomAnchor)
        ])

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.contentInset = .zero
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = .copySBold
        textView.textColor = .mainGrey
        addSubview(textView)
        let textViewMinHeightConstraint = textView.heightAnchor.constraint(greaterThanOrEqualToConstant: UIFont.copySBold.lineHeight)
        textViewMinHeightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 8),
            textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            textView.rightAnchor.constraint(equalTo: rightAnchor, constant: -10),
            textViewMinHeightConstraint,
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    private func setAudioControlsVisible(_ isVisible: Bool) {
        if isVisible {
            durationSeparatorLabel.isHidden = false
            durationLabel.isHidden = false
            playButton.isHidden = false
            titleLabelLeftConstraint.isActive = false
            titleLabelPlayButtonConstraint.isActive = true
            timestampLabelTitleLabelConstraint.isActive = false
            timestampLabelDurationLabelConstraint.isActive = true
        } else {
            durationSeparatorLabel.isHidden = true
            durationLabel.isHidden = true
            playButton.isHidden = true
            titleLabelPlayButtonConstraint.isActive = false
            titleLabelLeftConstraint.isActive = true
            timestampLabelTitleLabelConstraint.isActive = true
            timestampLabelDurationLabelConstraint.isActive = false
        }
    }

    func configure(from patient: Patient) {
        titleLabel.text = "Observation".localized
        timestampLabel.text = patient.updatedAt?.asLocalizedTime()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        textView.attributedText = NSAttributedString(string: patient.text ?? "", attributes: [
            .font: textView.font!,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textView.textColor!
        ])
        setAudioControlsVisible(false)
        var audioUrl: String?
        if let observation = patient as? Observation {
            audioUrl = observation.audioFile
        } else {
            audioUrl = patient.audioUrl
        }
        if let audioUrl = audioUrl {
            setAudioControlsVisible(true)
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

    @objc func playPressed(_ sender: Any) {
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
