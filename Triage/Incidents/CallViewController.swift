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
import UIKit

enum CallStatus {
    case connecting, ringing, connected, disconnected
}

class CallViewController: UIViewController, AgoraRtcEngineDelegate, AgoraRtmClientDelegate {
    weak var commandHeader: CommandHeader!
    weak var localView: UIView!
    weak var remoteView: UIView!
    weak var statusView: UIView!
    weak var statusLabel: UILabel!
    weak var statusSpinner: UIActivityIndicatorView!
    weak var flipButton: RoundButton!

    var rtcKit: AgoraRtcEngineKit!
    var rtmKit: AgoraRtmClientKit!

    var callId = UUID()
    var callStatus: CallStatus = .connecting
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

        let remoteView = UIView()
        remoteView.translatesAutoresizingMaskIntoConstraints = false
        remoteView.backgroundColor = .gray
        remoteView.layer.masksToBounds = true
        remoteView.layer.cornerRadius = 8
        remoteView.isHidden = true
        view.addSubview(remoteView)
        NSLayoutConstraint.activate([
            remoteView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25),
            remoteView.heightAnchor.constraint(equalTo: remoteView.widthAnchor, multiplier: 1.7),
            remoteView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            remoteView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        self.remoteView = remoteView

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

        let flipButton = RoundButton(frame: CGRect(x: 0, y: 0, width: 74, height: 74))
        flipButton.translatesAutoresizingMaskIntoConstraints = false
        flipButton.setImage(UIImage(named: "Update40px", in: PRKitBundle.instance, compatibleWith: nil), for: .normal)
        flipButton.tintColor = .white
        flipButton.alpha = 0.8
        flipButton.addTarget(self, action: #selector(flipPressed), for: .touchUpInside )
        view.addSubview(flipButton)
        NSLayoutConstraint.activate([
            flipButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            flipButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            flipButton.widthAnchor.constraint(equalToConstant: 74),
            flipButton.heightAnchor.constraint(equalToConstant: 74)
        ])

        let keys = TriageKeys()
        rtcKit = AgoraRtcEngineKit.sharedEngine(withAppId: keys.agoraAppId, delegate: self)
        let task = PRApiClient.shared.getRtcToken(channelName: callChannelName) { [weak self] (_, _, data, error) in
            if let error = error {
                // TODO: error handling
                print(error)
            } else if let data = data, let token = data["token"] as? String {
                guard let self = self else { return }
                let channelOptions = AgoraRtcChannelMediaOptions()
                channelOptions.channelProfile = .communication
                channelOptions.clientRoleType = .broadcaster
                channelOptions.publishMicrophoneTrack = true
                channelOptions.publishCameraTrack = true
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
                print("!!!", error)
            } else if let userId = AppSettings.userId {
                self.rtmKit = try? AgoraRtmClientKit(AgoraRtmClientConfig(appId: keys.agoraAppId, userId: userId), delegate: self)
                let task = PRApiClient.shared.getRtmToken(channelName: userId) { [weak self] (_, _, data, error) in
                    guard let self = self else { return }
                    if let error = error {
                        // TODO: error handling
                        print(error)
                    } else if let data = data as? [String: String], let token = data["token"] {
                        self.rtmKit.login(token) { [weak self] (_, error) in
                            guard let self = self else { return }
                            if let error = error {
                                // TODO: error handling
                                print(error)
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
                                            // TODO: error handling
                                            print(error)
                                            if error.errorCode == .channelReceiverOffline {
                                                DispatchQueue.main.async { [weak self] in
                                                    self?.statusView.isHidden = true
                                                    self?.presentAlert(title: "CallViewController.offline.title".localized,
                                                                       message: "CallViewController.offline.message".localized) { [weak self] in
                                                        self?.dismissAnimated()
                                                    }
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
                                    // TODO: error handling
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
                print(error)
            }
        }
        dismissAnimated()
    }

    @objc func flipPressed() {
        rtcKit.switchCamera()
    }

    // MARK: - AgoraRtcEngineDelegate

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        let localVideoCanvas = AgoraRtcVideoCanvas()
        localVideoCanvas.view = localView
        localVideoCanvas.uid = uid
        localVideoCanvas.renderMode = .hidden
        rtcKit.setupLocalVideo(localVideoCanvas)
        rtcKit.enableVideo()
        rtcKit.startPreview()
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        let remoteVideoCanvas = AgoraRtcVideoCanvas()
        remoteVideoCanvas.view = remoteView
        remoteVideoCanvas.uid = uid
        remoteVideoCanvas.renderMode = .hidden
        rtcKit.setupRemoteVideo(remoteVideoCanvas)
        remoteView.isHidden = false
        statusView.isHidden = true
        callStatus = .connected
        CallHelper.shared.connected(id: callId)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        callStatus = .disconnected
        CallHelper.shared.ended(id: callId, reason: .remoteEnded)
        presentAlert(title: "CallViewController.ended.title".localized, message: "CallViewController.ended.message".localized) { [weak self] in
            self?.dismissAnimated()
        }
    }
}
