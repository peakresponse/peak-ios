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
    weak var flipButton: RoundButton!

    var regionFacility: RegionFacility!
    var agoraKit: AgoraRtcEngineKit!

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
        view.addSubview(remoteView)
        NSLayoutConstraint.activate([
            remoteView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25),
            remoteView.heightAnchor.constraint(equalTo: remoteView.widthAnchor, multiplier: 1.7),
            remoteView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            remoteView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

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
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: keys.agoraAppId, delegate: self)
        agoraKit.enableVideo()
        agoraKit.startPreview()

        let localVideoCanvas = AgoraRtcVideoCanvas()
        localVideoCanvas.view = localView
        localVideoCanvas.uid = 0
        localVideoCanvas.renderMode = .hidden
        agoraKit.setupLocalVideo(localVideoCanvas)
    }

    @objc func cancelPressed() {
        dismissAnimated()
    }

    @objc func flipPressed() {
        agoraKit.switchCamera()
    }
}
