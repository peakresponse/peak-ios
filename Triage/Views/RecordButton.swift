//
//  RecordButton.swift
//  Triage
//
//  Created by Francis Li on 8/21/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import PRKit
import TranscriptionKit
import UIKit

class RecordIconButton: UIButton {
    var isBluetoothSelected = true

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var rect = super.imageRect(forContentRect: contentRect)
        rect.origin.x = 40
        return rect
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        var rect = super.titleRect(forContentRect: contentRect)
        if !isBluetoothSelected {
            rect.origin.x += 34
        }
        return rect
    }
}

enum RecordButtonState: String {
    case update, record, addRecording, stopAndSave
}

@objc protocol RecordButtonDelegate {
    @objc optional func recordButton(_ button: RecordButton, willPresent alert: UIAlertController) -> UIViewController
}

@IBDesignable
class RecordButton: UIControl {
    var recordButton: PRKit.Button!
    var recordButtonRightConstraint: NSLayoutConstraint!
    let bluetoothButton = UIButton(type: .custom)

    @IBOutlet weak var delegate: RecordButtonDelegate?

    var recordState: RecordButtonState = .record {
        didSet { updateButtonStates() }
    }
    @IBInspectable var RecordState: String? {
        get { return nil }
        set { recordState = RecordButtonState(rawValue: newValue ?? "") ?? .record }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // swiftlint:disable:next function_body_length
    private func commonInit() {
        backgroundColor = .clear

        let recordButton = PRKit.Button()
        recordButton.size = .medium
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.setTitle("Button.record".localized, for: .normal)
        recordButton.adjustsImageWhenHighlighted = false
        addSubview(recordButton)
        recordButtonRightConstraint = recordButton.rightAnchor.constraint(equalTo: rightAnchor)
        NSLayoutConstraint.activate([
            recordButton.topAnchor.constraint(equalTo: topAnchor),
            recordButton.leftAnchor.constraint(equalTo: leftAnchor),
            recordButtonRightConstraint,
            bottomAnchor.constraint(equalTo: recordButton.bottomAnchor)
        ])
        self.recordButton = recordButton

        bluetoothButton.setBackgroundImage(.resizableImage(withColor: .lowPriorityGrey, cornerRadius: 27,
                                                           borderColor: .clear, borderWidth: 3),
                                           for: .normal)
        bluetoothButton.setBackgroundImage(.resizableImage(withColor: .mainGrey, cornerRadius: 27,
                                                           borderColor: .clear, borderWidth: 3),
                                           for: .highlighted)
        bluetoothButton.setBackgroundImage(.resizableImage(withColor: .greyPeakBlue, cornerRadius: 27,
                                                           borderColor: .white, borderWidth: 3),
                                           for: .selected)
        bluetoothButton.setBackgroundImage(.resizableImage(withColor: .darkPeakBlue, cornerRadius: 27,
                                                           borderColor: .white, borderWidth: 3),
                                           for: [.selected, .highlighted])
        bluetoothButton.translatesAutoresizingMaskIntoConstraints = false
        bluetoothButton.adjustsImageWhenHighlighted = false
        bluetoothButton.setImage(UIImage(named: "Bluetooth"), for: .normal)
        bluetoothButton.addTarget(self, action: #selector(bluetoothPressed), for: .touchUpInside)
        bluetoothButton.addShadow(withOffset: CGSize(width: 0, height: 6), radius: 10, color: .dropShadow, opacity: 0.15)
        addSubview(bluetoothButton)
        NSLayoutConstraint.activate([
            bluetoothButton.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
            bluetoothButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -9),
            bluetoothButton.widthAnchor.constraint(equalToConstant: 54),
            bluetoothButton.heightAnchor.constraint(equalToConstant: 54)
        ])

        updateButtonStates()
    }

    override func invalidateIntrinsicContentSize() {
        recordButton.isLayoutVertical = false
        recordButton.invalidateIntrinsicContentSize()
        super.invalidateIntrinsicContentSize()
    }

    private func updateButtonStates() {
        switch recordState {
        case .stopAndSave:
            bluetoothButton.isHidden = true
            bluetoothButton.isSelected = true
            recordButton.style = .secondary
            recordButton.setImage(nil, for: .normal)
        default:
            recordButton.style = .primary
            switch recordState {
            case .record, .addRecording:
                bluetoothButton.isHidden = Transcriber.bluetoothHFPInputs.count == 0
                bluetoothButton.isSelected = bluetoothButton.isHidden || AppSettings.audioInputPortUID != nil
                recordButton.setImage(UIImage(named: "RecordMic24px", in: PRKitBundle.instance, compatibleWith: nil), for: .normal)
            case .update:
                bluetoothButton.isHidden = true
                bluetoothButton.isSelected = true
                recordButton.setImage(nil, for: .normal)
            case .stopAndSave:
                break
            }
        }
        recordButton.setTitle("Button.\(recordState.rawValue)".localized, for: .normal)
        recordButtonRightConstraint.constant = bluetoothButton.isSelected ? 0 : -68
    }

    @objc func bluetoothPressed() {
        if AppSettings.audioInputPortUID != nil {
            // toggle Bluetooth off
            AppSettings.audioInputPortUID = nil
        } else {
            // select Bluetooth input, provide prompt if multiple
            let inputPorts = Transcriber.bluetoothHFPInputs
            if inputPorts.count > 1 {
                let alert = UIAlertController(title: "RecordButton.selectInputLabel".localized, message: nil, preferredStyle: .actionSheet)
                for inputPort in inputPorts {
                    alert.addAction(UIAlertAction(title: inputPort.portName, style: .default, handler: { [weak self] (_) in
                        AppSettings.audioInputPortUID = inputPort.uid
                        self?.bluetoothButton.isSelected = true
                    }))
                }
                alert.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel, handler: nil))
                if let vc = delegate?.recordButton?(self, willPresent: alert) {
                    vc.presentAnimated(alert)
                }
            } else {
                AppSettings.audioInputPortUID = inputPorts[0].uid
            }
        }
        updateButtonStates()
    }

    // MARK: - UIControl

    override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        recordButton.addTarget(target, action: action, for: controlEvents)
    }

    override func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
        recordButton.removeTarget(target, action: action, for: controlEvents)
    }
}
