//
//  CallViewController.swift
//  Triage
//
//  Created by Francis Li on 12/4/25.
//  Copyright © 2025 Francis Li. All rights reserved.
//

import AgoraRtcKit
import AgoraRtmKit
import Keys
import PRKit
import RollbarNotifier
import UIKit

enum CallReason {
    case hospitalTeamActivation, medication, procedure, ringdown
}

enum CallStatus {
    case connecting, ringing, connected, disconnected
}

@objc protocol CallViewControllerDelegate {
    func callViewControllerDidFinish(_ vc: CallViewController)
}

class CallViewController: UIViewController, AgoraRtcEngineDelegate, AgoraRtmClientDelegate {
    weak var commandHeader: CommandHeader!
    weak var localView: UIView!
    weak var localPlaceholderView: UIView!
    weak var remoteView: UIView!
    weak var remotePlaceholderView: UIView!
    weak var statusView: UIView!
    weak var statusLabel: UILabel!
    weak var statusSpinner: UIActivityIndicatorView!
    weak var flipButton: RoundButton!
    weak var audioButton: RoundButton!
    weak var videoButton: RoundButton!

    var rtcKit: AgoraRtcEngineKit!
    var rtmKit: AgoraRtmClientKit!

    weak var delegate: CallViewControllerDelegate?

    var callId = UUID()
    var callReason: CallReason!
    var callStatus: CallStatus = .connecting
    var callConnectedAt: Date?
    var callName: String!
    var callChannelName: String!
    var signalChannelName: String!

    init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .coverVertical
        edgesForExtendedLayout = [.all]
    }

    deinit {
        rtcKit?.stopPreview()
        rtcKit?.leaveChannel(nil)
        rtcKit = nil
        AgoraRtcEngineKit.destroy()

        rtmKit?.logout()
        rtmKit?.destroy()
        rtmKit = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background

        let commandHeader = CommandHeader()
        commandHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(commandHeader)
        NSLayoutConstraint.activate([
            commandHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            commandHeader.leftAnchor.constraint(equalTo: view.leftAnchor),
            commandHeader.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        self.commandHeader = commandHeader

        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized, style: .done, target: self, action: #selector(donePressed))

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .h4SemiBold
        titleLabel.textColor = .text
        titleLabel.text = callName
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        commandHeader.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: commandHeader.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: commandHeader.centerYAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: commandHeader.widthAnchor, multiplier: 0.8)
        ])

        let localView = UIView()
        localView.translatesAutoresizingMaskIntoConstraints = false
        localView.backgroundColor = .black
        view.addSubview(localView)
        NSLayoutConstraint.activate([
            localView.topAnchor.constraint(equalTo: commandHeader.bottomAnchor),
            localView.leftAnchor.constraint(equalTo: view.leftAnchor),
            localView.rightAnchor.constraint(equalTo: view.rightAnchor),
            localView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.localView = localView

        let localPlaceholderView = UIView()
        localPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        localPlaceholderView.backgroundColor = .black
        view.addSubview(localPlaceholderView)
        NSLayoutConstraint.activate([
            localPlaceholderView.topAnchor.constraint(equalTo: localView.topAnchor),
            localPlaceholderView.leftAnchor.constraint(equalTo: localView.leftAnchor),
            localPlaceholderView.rightAnchor.constraint(equalTo: localView.rightAnchor),
            localPlaceholderView.bottomAnchor.constraint(equalTo: localView.bottomAnchor)
        ])
        self.localPlaceholderView = localPlaceholderView

        let localImageView = UIImageView(image: UIImage(named: "User"))
        localImageView.translatesAutoresizingMaskIntoConstraints = false
        localImageView.tintColor = .white
        localImageView.contentMode = .scaleAspectFit
        localPlaceholderView.addSubview(localImageView)
        NSLayoutConstraint.activate([
            localImageView.centerXAnchor.constraint(equalTo: localPlaceholderView.centerXAnchor),
            localImageView.centerYAnchor.constraint(equalTo: localPlaceholderView.centerYAnchor),
            localImageView.widthAnchor.constraint(equalTo: localPlaceholderView.widthAnchor, multiplier: 0.5)
        ])

        let remoteView = UIView()
        remoteView.translatesAutoresizingMaskIntoConstraints = false
        remoteView.backgroundColor = .black
        remoteView.isHidden = true
        remoteView.addShadow(withOffset: .zero, radius: 4, color: .white, opacity: 0.3)
        view.addSubview(remoteView)
        NSLayoutConstraint.activate([
            remoteView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25),
            remoteView.heightAnchor.constraint(equalTo: remoteView.widthAnchor, multiplier: 1.7),
            remoteView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            remoteView.topAnchor.constraint(equalTo: commandHeader.bottomAnchor, constant: 20)
        ])
        self.remoteView = remoteView

        let remotePlaceholderView = UIView()
        remotePlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        remotePlaceholderView.backgroundColor = .black
        remotePlaceholderView.isHidden = true
        view.addSubview(remotePlaceholderView)
        NSLayoutConstraint.activate([
            remotePlaceholderView.topAnchor.constraint(equalTo: remoteView.topAnchor),
            remotePlaceholderView.leftAnchor.constraint(equalTo: remoteView.leftAnchor),
            remotePlaceholderView.rightAnchor.constraint(equalTo: remoteView.rightAnchor),
            remotePlaceholderView.bottomAnchor.constraint(equalTo: remoteView.bottomAnchor)
        ])
        self.remotePlaceholderView = remotePlaceholderView

        let remoteImageView = UIImageView(image: UIImage(named: "User"))
        remoteImageView.translatesAutoresizingMaskIntoConstraints = false
        remoteImageView.tintColor = .white
        remoteImageView.contentMode = .scaleAspectFit
        remotePlaceholderView.addSubview(remoteImageView)
        NSLayoutConstraint.activate([
            remoteImageView.centerXAnchor.constraint(equalTo: remotePlaceholderView.centerXAnchor),
            remoteImageView.centerYAnchor.constraint(equalTo: remotePlaceholderView.centerYAnchor),
            remoteImageView.widthAnchor.constraint(equalTo: remotePlaceholderView.widthAnchor, multiplier: 0.5)
        ])

        let statusView = UIView()
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.backgroundColor = .black.withAlphaComponent(0.5)
        statusView.layer.masksToBounds = true
        statusView.layer.cornerRadius = 16
        view.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.centerXAnchor.constraint(equalTo: localView.centerXAnchor),
            statusView.centerYAnchor.constraint(equalTo: localView.centerYAnchor),
            statusView.widthAnchor.constraint(lessThanOrEqualTo: localView.widthAnchor, multiplier: 0.8)
        ])
        self.statusView = statusView

        let statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .h3SemiBold
        statusLabel.textColor = .white
        statusLabel.text = "CallViewController.connecting".localized
        statusLabel.numberOfLines = 0
        statusView.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: statusView.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: statusView.topAnchor, constant: 20),
            statusLabel.leftAnchor.constraint(greaterThanOrEqualTo: statusView.leftAnchor, constant: 20),
            statusLabel.rightAnchor.constraint(lessThanOrEqualTo: statusView.rightAnchor, constant: -20)
        ])
        self.statusLabel = statusLabel

        let statusSpinner = UIActivityIndicatorView(style: .large)
        statusSpinner.translatesAutoresizingMaskIntoConstraints = false
        statusSpinner.color = .white
        statusSpinner.startAnimating()
        statusView.addSubview(statusSpinner)
        NSLayoutConstraint.activate([
            statusSpinner.centerXAnchor.constraint(equalTo: statusView.centerXAnchor),
            statusSpinner.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            statusView.bottomAnchor.constraint(equalTo: statusSpinner.bottomAnchor, constant: 20)
        ])
        self.statusSpinner = statusSpinner

        let videoButton = RoundButton(frame: CGRect(x: 0, y: 0, width: 74, height: 74))
        videoButton.translatesAutoresizingMaskIntoConstraints = false
        videoButton.setImage(UIImage(named: "VidOff40px", in: PRKitBundle.instance, compatibleWith: nil), for: .normal)
        videoButton.setImage(UIImage(named: "VidOn40px", in: PRKitBundle.instance, compatibleWith: nil), for: .selected)
        videoButton.tintColor = .white
        videoButton.alpha = 0.8
        videoButton.addTarget(self, action: #selector(videoPressed), for: .touchUpInside )
        videoButton.isEnabled = false
        view.addSubview(videoButton)
        NSLayoutConstraint.activate([
            videoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            videoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            videoButton.widthAnchor.constraint(equalToConstant: 74),
            videoButton.heightAnchor.constraint(equalToConstant: 74)
        ])
        self.videoButton = videoButton

        let flipButton = RoundButton(frame: CGRect(x: 0, y: 0, width: 74, height: 74))
        flipButton.translatesAutoresizingMaskIntoConstraints = false
        flipButton.setImage(UIImage(named: "Update40px", in: PRKitBundle.instance, compatibleWith: nil), for: .normal)
        flipButton.tintColor = .white
        flipButton.alpha = 0.8
        flipButton.addTarget(self, action: #selector(flipPressed), for: .touchUpInside )
        flipButton.isEnabled = false
        view.addSubview(flipButton)
        NSLayoutConstraint.activate([
            flipButton.leftAnchor.constraint(equalTo: videoButton.rightAnchor, constant: 20),
            flipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            flipButton.widthAnchor.constraint(equalToConstant: 74),
            flipButton.heightAnchor.constraint(equalToConstant: 74)
        ])
        self.flipButton = flipButton

        let audioButton = RoundButton(frame: CGRect(x: 0, y: 0, width: 74, height: 74))
        audioButton.translatesAutoresizingMaskIntoConstraints = false
        audioButton.setImage(UIImage(named: "MicOff40px", in: PRKitBundle.instance, compatibleWith: nil), for: .normal)
        audioButton.setImage(UIImage(named: "MicOn40px", in: PRKitBundle.instance, compatibleWith: nil), for: .selected)
        audioButton.tintColor = .white
        audioButton.alpha = 0.8
        audioButton.addTarget(self, action: #selector(audioPressed), for: .touchUpInside )
        audioButton.isEnabled = false
        audioButton.isSelected = true
        view.addSubview(audioButton)
        NSLayoutConstraint.activate([
            audioButton.rightAnchor.constraint(equalTo: videoButton.leftAnchor, constant: -20),
            audioButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            audioButton.widthAnchor.constraint(equalToConstant: 74),
            audioButton.heightAnchor.constraint(equalToConstant: 74)
        ])
        self.audioButton = audioButton

        let keys = TriageKeys()
        rtcKit = AgoraRtcEngineKit.sharedEngine(withAppId: keys.agoraAppId, delegate: self)
        let task = PRApiClient.shared.getRtcToken(channelName: callChannelName) { [weak self] (_, _, data, error) in
            if let error = error {
                Rollbar.errorError(error)
                DispatchQueue.main.async { [weak self] in
                    self?.presentUnexpectedErrorAlert()
                }
            } else if let data = data, let token = data["token"] as? String {
                guard let self = self else { return }
                let channelOptions = AgoraRtcChannelMediaOptions()
                channelOptions.channelProfile = .communication
                channelOptions.clientRoleType = .broadcaster
                channelOptions.publishMicrophoneTrack = true
                channelOptions.publishCameraTrack = false
                channelOptions.autoSubscribeAudio = true
                channelOptions.autoSubscribeVideo = true
                self.rtcKit.joinChannel(byToken: token, channelId: self.callChannelName, uid: 0, mediaOptions: channelOptions)
            }
        }
        task.resume()
    }

    func ring(_ regionFacility: RegionFacility, with report: Report?) {
        callName = regionFacility.description
        callChannelName = AppSettings.userId ?? ""
        signalChannelName = "H-\(regionFacility.facility?.stateId ?? "")-\(regionFacility.facility?.locationCode ?? "")"
        let ringdown: Any = report?.asRingdownJSON() ?? NSNull()
        let keys = TriageKeys()
        CallHelper.shared.start(id: callId, to: callName) { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                Rollbar.errorError(error)
                DispatchQueue.main.async { [weak self] in
                    self?.presentUnexpectedErrorAlert()
                }
            } else if let userId = AppSettings.userId {
                self.rtmKit = try? AgoraRtmClientKit(AgoraRtmClientConfig(appId: keys.agoraAppId, userId: userId), delegate: self)
                let task = PRApiClient.shared.getRtmToken(channelName: userId) { [weak self] (_, _, data, error) in
                    guard let self = self else { return }
                    if let error = error {
                        Rollbar.errorError(error)
                        DispatchQueue.main.async { [weak self] in
                            self?.presentUnexpectedErrorAlert()
                        }
                    } else if let data = data as? [String: String], let token = data["token"] {
                        self.rtmKit.login(token) { [weak self] (_, error) in
                            guard let self = self else { return }
                            if let error = error {
                                Rollbar.errorError(error)
                                DispatchQueue.main.async { [weak self] in
                                    self?.presentUnexpectedErrorAlert()
                                }
                            } else {
                                let publishOptions = AgoraRtmPublishOptions()
                                publishOptions.channelType = .user
                                let payload: [String: Any] = [
                                    "id": self.callId.uuidString.lowercased(),
                                    "status": "ringing",
                                    "userId": userId,
                                    "ringdown": ringdown,
                                    "calledAt": Date().asISO8601String()
                                ]
                                if let data = try? JSONSerialization.data(withJSONObject: payload, options: []) {
                                    self.rtmKit.publish(channelName: signalChannelName, data: data, option: publishOptions) { [weak self] (_, error) in
                                        guard let self = self else { return }
                                        if let error = error {
                                            Rollbar.errorError(error)
                                            if error.errorCode == .channelReceiverOffline {
                                                DispatchQueue.main.async { [weak self] in
                                                    self?.statusView.isHidden = true
                                                    self?.presentAlert(title: "CallViewController.offline.title".localized,
                                                                       message: "CallViewController.offline.message".localized) { [weak self] in
                                                        guard let self = self else { return }
                                                        CallHelper.shared.ended(id: callId, reason: .failed)
                                                        self.delegate?.callViewControllerDidFinish(self)
                                                    }
                                                }
                                            } else {
                                                DispatchQueue.main.async { [weak self] in
                                                    self?.presentUnexpectedErrorAlert()
                                                }
                                            }
                                        } else {
                                            self.callStatus = .ringing
                                            DispatchQueue.main.async { [weak self] in
                                                self?.statusLabel.text = "CallViewController.ringing".localized
                                            }
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async { [weak self] in
                                        self?.presentUnexpectedErrorAlert()
                                    }
                                }
                            }
                        }
                    }
                }
                task.resume()
            }
        }
    }

    @objc func donePressed() {
        if callStatus == .ringing, let rtmKit = rtmKit {
            let publishOptions = AgoraRtmPublishOptions()
            publishOptions.channelType = .user
            let payload: [String: Any] = [
                "id": callId.uuidString.lowercased(),
                "status": "cancelled",
                "cancelledAt": Date().asISO8601String()
            ]
            if let data = try? JSONSerialization.data(withJSONObject: payload) {
                rtmKit.publish(channelName: signalChannelName, data: data, option: publishOptions)
            }
        }
        CallHelper.shared.end(id: callId) { [weak self] (error) in
            if let error = error {
                Rollbar.errorError(error)
                DispatchQueue.main.async { [weak self] in
                    self?.presentUnexpectedErrorAlert()
                }
            }
        }
        delegate?.callViewControllerDidFinish(self)
    }

    @objc func flipPressed() {
        rtcKit.switchCamera()
    }

    @objc func audioPressed() {
        audioButton.isSelected = !audioButton.isSelected
        rtcKit.enableLocalAudio(audioButton.isSelected)
        updateChannel()
    }

    @objc func videoPressed() {
        videoButton.isSelected = !videoButton.isSelected
        rtcKit.enableLocalVideo(videoButton.isSelected)
        if videoButton.isSelected {
            rtcKit.startPreview()
            localPlaceholderView.isHidden = true
        } else {
            rtcKit.stopPreview()
            localPlaceholderView.isHidden = false
        }
        updateChannel()
    }

    func updateChannel() {
        let channelOptions = AgoraRtcChannelMediaOptions()
        channelOptions.channelProfile = .communication
        channelOptions.clientRoleType = .broadcaster
        channelOptions.publishMicrophoneTrack = audioButton.isSelected
        channelOptions.publishCameraTrack = videoButton.isSelected
        channelOptions.autoSubscribeAudio = true
        channelOptions.autoSubscribeVideo = true
        rtcKit.updateChannel(with: channelOptions)
    }

    // MARK: - AgoraRtcEngineDelegate

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        let localVideoCanvas = AgoraRtcVideoCanvas()
        localVideoCanvas.view = localView
        localVideoCanvas.uid = uid
        localVideoCanvas.renderMode = .hidden
        rtcKit.setupLocalVideo(localVideoCanvas)
        rtcKit.enableVideo()
        audioButton.isEnabled = true
        videoButton.isEnabled = true
        flipButton.isEnabled = true
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        let remoteVideoCanvas = AgoraRtcVideoCanvas()
        remoteVideoCanvas.view = remoteView
        remoteVideoCanvas.uid = uid
        remoteVideoCanvas.renderMode = .hidden
        rtcKit.setupRemoteVideo(remoteVideoCanvas)
        remoteView.isHidden = false
        remotePlaceholderView.isHidden = false
        statusView.isHidden = true
        callStatus = .connected
        callConnectedAt = Date()
        CallHelper.shared.connected(id: callId)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        callStatus = .disconnected
        CallHelper.shared.ended(id: callId, reason: .remoteEnded)
        presentAlert(title: "CallViewController.ended.title".localized, message: "CallViewController.ended.message".localized) { [weak self] in
            guard let self = self else { return }
            self.delegate?.callViewControllerDidFinish(self)
        }
    }

    func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        remoteVideoStateChangedOfUid uid: UInt,
        state: AgoraVideoRemoteState,
        reason: AgoraVideoRemoteReason,
        elapsed: Int
    ) {
        if state == .stopped {
            remotePlaceholderView.isHidden = false
        } else {
            remotePlaceholderView.isHidden = true
        }
    }
}
