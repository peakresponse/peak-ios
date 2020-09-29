//
//  RecordButton.swift
//  Triage
//
//  Created by Francis Li on 8/21/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

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
    let recordButton = RecordIconButton(type: .custom)
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

    private func commonInit() {
        backgroundColor = .clear

        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.titleLabel?.font = .copyLBold
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.setTitle("Button.record".localized, for: .normal)
        recordButton.adjustsImageWhenHighlighted = false
        recordButton.setBackgroundImage(.resizableImage(withColor: .peakBlue, cornerRadius: 36), for: .normal)
        recordButton.setBackgroundImage(.resizableImage(withColor: .darkPeakBlue, cornerRadius: 36), for: .highlighted)
        recordButton.addShadow(withOffset: CGSize(width: 0, height: 6), radius: 10, color: .black, opacity: 0.15)
        addSubview(recordButton)
        recordButtonRightConstraint = recordButton.rightAnchor.constraint(equalTo: rightAnchor)
        NSLayoutConstraint.activate([
            recordButton.topAnchor.constraint(equalTo: topAnchor),
            recordButton.leftAnchor.constraint(equalTo: leftAnchor),
            recordButton.heightAnchor.constraint(equalToConstant: 72),
            recordButtonRightConstraint,
            bottomAnchor.constraint(equalTo: recordButton.bottomAnchor)
        ])

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
        bluetoothButton.addShadow(withOffset: CGSize(width: 0, height: 6), radius: 10, color: .black, opacity: 0.15)
        addSubview(bluetoothButton)
        NSLayoutConstraint.activate([
            bluetoothButton.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
            bluetoothButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -9),
            bluetoothButton.widthAnchor.constraint(equalToConstant: 54),
            bluetoothButton.heightAnchor.constraint(equalToConstant: 54)
        ])

        updateButtonStates()
    }

    private func updateButtonStates() {
        switch recordState {
        case .stopAndSave:
            bluetoothButton.isHidden = true
            bluetoothButton.isSelected = true
            recordButton.setTitleColor(.peakBlue, for: .normal)
            recordButton.setBackgroundImage(.resizableImage(withColor: .white, cornerRadius: 36), for: .normal)
            recordButton.setBackgroundImage(.resizableImage(withColor: .lowPriorityGrey, cornerRadius: 36), for: .highlighted)
            recordButton.setImage(UIImage(named: "StopAndSave"), for: .normal)
        default:
            recordButton.setTitleColor(.white, for: .normal)
            recordButton.setBackgroundImage(.resizableImage(withColor: .peakBlue, cornerRadius: 36), for: .normal)
            recordButton.setBackgroundImage(.resizableImage(withColor: .darkPeakBlue, cornerRadius: 36), for: .highlighted)
            switch recordState {
            case .record, .addRecording:
                bluetoothButton.isHidden = AudioHelper.bluetoothHFPInputs.count == 0
                bluetoothButton.isSelected = bluetoothButton.isHidden || AppSettings.audioInputPortUID != nil
                recordButton.setImage(UIImage(named: "Microphone"), for: .normal)
            case .update:
                bluetoothButton.isHidden = true
                bluetoothButton.isSelected = true
                recordButton.setImage(nil, for: .normal)
            case .stopAndSave:
                break
            }
        }
        recordButton.setTitle("Button.\(recordState.rawValue)".localized, for: .normal)
        recordButton.isBluetoothSelected = bluetoothButton.isSelected
        recordButtonRightConstraint.constant = bluetoothButton.isSelected ? 0 : -68
    }

    @objc func bluetoothPressed() {
        if AppSettings.audioInputPortUID != nil {
            // toggle Bluetooth off
            AppSettings.audioInputPortUID = nil
        } else {
            // select Bluetooth input, provide prompt if multiple
            let inputPorts = AudioHelper.bluetoothHFPInputs
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
