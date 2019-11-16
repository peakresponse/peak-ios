//
//  AudioHelper.swift
//  Triage
//
//  Created by Francis Li on 11/14/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import AVFoundation
import Speech

@objc protocol AudioHelperDelgate {
    @objc optional func audioHelper(_ audioHelper: AudioHelper, didFinishPlaying successfully: Bool)
    @objc optional func audioHelper(_ audioHelper: AudioHelper, didPlay seconds: TimeInterval, formattedDuration duration: String)
    @objc optional func audioHelper(_ audioHelper: AudioHelper, didRecognizeText text: String)
    @objc optional func audioHelper(_ audioHelper: AudioHelper, didRecord seconds: TimeInterval, formattedDuration duration: String)
    @objc optional func audioHelper(_ audioHelper: AudioHelper, didRequestSpeechAuthorization status: SFSpeechRecognizerAuthorizationStatus)
}

class AudioHelper: NSObject, AVAudioPlayerDelegate {
    let audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer()
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?

    var fileURL: URL!
    var recordingLength: TimeInterval = 0
    var recordingLengthFormatted: String {
        return String(format: "%2.0f:%02.0f", recordingLength / 60, recordingLength.truncatingRemainder(dividingBy: 60))
    }
    var recordingStart: Date?
    var timer: Timer?
    var player: AVAudioPlayer?
    var isPlaying: Bool {
        return player?.isPlaying ?? false
    }
    
    weak var delegate: AudioHelperDelgate?

    override init() {
        super.init()
        reset()
    }

    func reset() {
        player = nil
        let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        fileURL = tempDirURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
    }
    
    func prepareToPlay() throws {
        player = try AVAudioPlayer(contentsOf: fileURL)
        recordingLength = player?.duration ?? 0
        player?.delegate = self
        player?.prepareToPlay()
        player?.volume = 1
    }
    
    func playPressed() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback)

        if player == nil {
            try prepareToPlay()
        }
        player?.play()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] (timer) in
            guard let self = self else { return }
            if let seconds = self.player?.currentTime {
                let duration = String(format: "%2.0f:%02.0f", seconds / 60, seconds.truncatingRemainder(dividingBy: 60))
                self.delegate?.audioHelper?(self, didPlay: seconds, formattedDuration: duration)
            }
        }
    }

    func stopPressed() {
        player?.stop()
        player = nil
        timer?.invalidate()
        timer = nil
    }
    
    func recordPressed() throws {
        if SFSpeechRecognizer.authorizationStatus() == .authorized {
            if !audioEngine.isRunning {
                try startRecording()
            }
        } else {
            SFSpeechRecognizer.requestAuthorization { [weak self] (status) in
                guard let self = self else { return }
                self.delegate?.audioHelper?(self, didRequestSpeechAuthorization: status)
            }
        }
    }

    func recordReleased() {
        if audioEngine.isRunning {
            stopRecording()
        }
    }

    private func startRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] (result, error) in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                isFinal = result.isFinal
                let text = result.bestTranscription.formattedString
                if let self = self {
                    self.delegate?.audioHelper?(self, didRecognizeText: text)
                }
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self?.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self?.recognitionRequest = nil
                self?.recognitionTask = nil
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let audioFile = try AVAudioFile(forWriting: fileURL, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC], commonFormat: recordingFormat.commonFormat, interleaved: false)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self?.recognitionRequest?.append(buffer)
            do {
                try audioFile.write(from: buffer)
            } catch {
                print(error)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        recordingStart = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] (timer) in
            guard let self = self else { return }
            let now = Date()
            if let start = self.recordingStart {
                let seconds = self.recordingLength + start.distance(to: now)
                let duration = String(format: "%2.0f:%02.0f", seconds / 60, seconds.truncatingRemainder(dividingBy: 60))
                self.delegate?.audioHelper?(self, didRecord: seconds, formattedDuration: duration)
            }
        }
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()

        timer?.invalidate()
        timer = nil
        let now = Date()
        if let start = recordingStart {
            recordingLength += start.distance(to: now)
        }
        recordingStart = nil
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print(error)
        }
        delegate?.audioHelper?(self, didFinishPlaying: false)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.audioHelper?(self, didFinishPlaying: flag)
    }
}
