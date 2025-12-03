//
//  VideoCallViewController.swift
//  Triage
//
//  Created by Francis Li on 11/20/25.
//  Copyright © 2025 Francis Li. All rights reserved.
//

import AgoraRtcKit
import AgoraRtmKit
import Keys
import PRKit
import UIKit

class VideoCallViewController: UIViewController, AgoraRtcEngineDelegate, AgoraRtmClientDelegate {
    weak var commandHeader: CommandHeader!
    weak var localView: UIView!
    weak var remoteView: UIView!
    weak var statusView: UIView!
    weak var statusLabel: UILabel!
    weak var statusSpinner: UIActivityIndicatorView!
    weak var flipButton: RoundButton!

    var regionFacility: RegionFacility!
    var report: Report!
    var rtmKit: AgoraRtmClientKit!
    var rtcKit: AgoraRtcEngineKit!
    var registered = false

    let callId = UUID().uuidString.lowercased()
    var userId: String!
    var signalChannelName: String!
    var callChannelName: String!

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

        signalChannelName = "H-\(regionFacility.facility?.stateId ?? "")-\(regionFacility.facility?.locationCode ?? "")"
        userId = AppSettings.userId
        callChannelName = userId

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

        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized, style: .done, target: self, action: #selector(cancelPressed))

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .h4SemiBold
        titleLabel.textColor = .text
        titleLabel.text = regionFacility.description
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
        statusLabel.text = "VideoCallViewController.connecting".localized
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
        if let userId = userId {
            rtmKit = try? AgoraRtmClientKit(AgoraRtmClientConfig(appId: keys.agoraAppId, userId: userId), delegate: self)
            if rtmKit != nil {
                rtcKit = AgoraRtcEngineKit.sharedEngine(withAppId: keys.agoraAppId, delegate: self)
                let result = rtcKit.registerLocalUserAccount(userId, appId: keys.agoraAppId)
                if result != 0 {
                    // TODO: error handling
                }
            } else {
                // TODO: error handling
            }
        } else {
            // TODO: error handling
        }
    }

    @objc func cancelPressed() {
        if let rtmKit = rtmKit, let userId = userId {
            let publishOptions = AgoraRtmPublishOptions()
            publishOptions.channelType = .user
            let payload: [String: Any] = [
                "id": callId,
                "status": "cancelled",
                "userId": userId,
                "cancelledAt": Date().asISO8601String()
            ]
            if let data = try? JSONSerialization.data(withJSONObject: payload) {
                rtmKit.publish(channelName: signalChannelName, data: data, option: publishOptions)
            }
        }
        dismissAnimated()
    }

    @objc func flipPressed() {
        rtcKit.switchCamera()
    }

    // MARK: - AgoraRtcEngineDelegate

    func rtcEngine(_ engine: AgoraRtcEngineKit, didLocalUserRegisteredWithUserId uid: UInt, userAccount: String) {
        // for some reason, receiving this callback twice after one register call
        if !registered {
            registered = true
            // start local video preview
            let localVideoCanvas = AgoraRtcVideoCanvas()
            localVideoCanvas.view = localView
            localVideoCanvas.uid = uid
            localVideoCanvas.renderMode = .hidden
            rtcKit.setupLocalVideo(localVideoCanvas)
            rtcKit.enableVideo()
            rtcKit.startPreview()
            // get an auth token for a channel named for this user
            let task = PRApiClient.shared.getToken(channelName: userAccount) { [weak self] (_, _, data, error) in
                if let error = error {
                    // TODO: error handling
                    print(error)
                } else if let data = data, let token = data["token"] as? String {
                    // log in to signaling
                    self?.rtmKit.login(token) { [weak self] (_, error) in
                        guard let self = self, let regionFacility = self.regionFacility else { return }
                        if let error = error {
                            // TODO: error handling
                            print(error)
                        } else {
                            // "ring" the hospital user
                            let subscribeOptions = AgoraRtmSubscribeOptions()
                            subscribeOptions.features = [.presence]
                            self.rtmKit.subscribe(channelName: self.signalChannelName, option: subscribeOptions) { [weak self] (response, error) in
                                guard let self = self else { return }
                                if let error = error {
                                    // TODO: error handling
                                    print(error)
                                } else {
                                    print("response", response)
                                    let publishOptions = AgoraRtmPublishOptions()
                                    publishOptions.channelType = .user
                                    let payload: [String: Any] = [
                                        "id": callId,
                                        "status": "ringing",
                                        "userId": userAccount,
                                        "ringdown": report.asRingdownJSON(),
                                        "calledAt": Date().asISO8601String()
                                    ]
                                    if let data = try? JSONSerialization.data(withJSONObject: payload, options: []) {
                                        self.rtmKit.publish(channelName: self.signalChannelName, data: data, option: publishOptions) { [weak self] (_, error) in
                                            guard let self = self else { return }
                                            if let error = error {
                                                // TODO: error handling
                                                print(error)
                                                if error.errorCode == .channelReceiverOffline {
                                                    DispatchQueue.main.async { [weak self] in
                                                        self?.statusView.isHidden = true
                                                        self?.presentAlert(title: "VideoCallViewController.offline.title".localized,
                                                                           message: "VideoCallViewController.offline.message".localized) { [weak self] in
                                                            self?.dismissAnimated()
                                                        }
                                                    }
                                                }
                                            } else {
                                                DispatchQueue.main.async { [weak self] in
                                                    self?.statusLabel.text = "VideoCallViewController.ringing".localized
                                                }
                                                let channelOptions = AgoraRtcChannelMediaOptions()
                                                channelOptions.channelProfile = .communication
                                                channelOptions.clientRoleType = .broadcaster
                                                channelOptions.publishMicrophoneTrack = true
                                                channelOptions.publishCameraTrack = true
                                                channelOptions.autoSubscribeAudio = true
                                                channelOptions.autoSubscribeVideo = true
                                                self.rtcKit.joinChannel(byToken: token, channelId: self.callChannelName, userAccount: userAccount, mediaOptions: channelOptions)
                                            }
                                        }
                                    } else {
                                        // TODO: error handling
                                    }
                                }
                            }
                        }
                    }
                }
            }
            task.resume()
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("didJoinedOfUid", uid)
        let remoteVideoCanvas = AgoraRtcVideoCanvas()
        remoteVideoCanvas.view = remoteView
        remoteVideoCanvas.uid = uid
        remoteVideoCanvas.renderMode = .hidden
        rtcKit.setupRemoteVideo(remoteVideoCanvas)
        remoteView.isHidden = false
        statusView.isHidden = true
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("didOfflineOfUid", uid, reason)
        dismissAnimated()
    }

    // MARK: - AgoraRtmClientDelegate

    func rtmKit(_ rtmKit: AgoraRtmClientKit, didReceivePresenceEvent event: AgoraRtmPresenceEvent) {
        print("didReceivePresenceEvent", event, "User \(event.publisher) is now \(event.type)")
    }
}
