//
//  BaseField.swift
//  Triage
//
//  Created by Francis Li on 9/4/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit
import PRKit

enum FormFieldStyle: String {
    case input, onboarding
}

@objc protocol FormFieldDelegate {
    @objc optional func formFieldShouldBeginEditing(_ field: BaseField) -> Bool
    @objc optional func formFieldDidBeginEditing(_ field: BaseField)
    @objc optional func formFieldShouldEndEditing(_ field: BaseField) -> Bool
    @objc optional func formFieldDidEndEditing(_ field: BaseField)
    @objc optional func formFieldShouldReturn(_ field: BaseField) -> Bool
    @objc optional func formFieldDidChange(_ field: BaseField)
    @objc optional func formFieldDidConfirmStatus(_ field: BaseField)
}

class BaseField: UIView, Localizable {
    weak var contentView: UIView!
    var contentViewConstraints: [NSLayoutConstraint]!
    weak var statusButton: UIButton!
    var statusButtonWidthConstraint: NSLayoutConstraint!
    weak var label: UILabel!
    var labelTopConstraint: NSLayoutConstraint!

    private var _detailLabel: UILabel!
    var detailLabel: UILabel {
        if _detailLabel == nil {
            initDetailLabel()
        }
        return _detailLabel
    }
    private var _alertLabel: UILabel!
    var alertLabel: UILabel {
        if _alertLabel == nil {
            initAlertLabel()
        }
        return _alertLabel
    }
    private var _statusLabel: UILabel!
    var statusLabel: UILabel {
        if _statusLabel == nil {
            initStatusLabel()
        }
        return _statusLabel
    }

    var status: PredictionStatus = .none {
        didSet { updateStyle() }
    }

    var style: FormFieldStyle = .input {
        didSet { updateStyle() }
    }

    @objc var text: String?

    @IBOutlet weak var delegate: FormFieldDelegate?

    @IBInspectable var Style: String {
        get { return style.rawValue }
        set { style = FormFieldStyle(rawValue: newValue) ?? .input }
    }

    @IBInspectable var l10nKey: String? {
        get { return nil }
        set { label.l10nKey = newValue }
    }

    @IBInspectable var labelText: String? {
        get { return label.text }
        set { label.text = newValue }
    }

    @IBInspectable var attributeKey: String?

    @IBInspectable var isPlainText: Bool = false {
        didSet { updateStyle() }
    }

    var isEditing = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        updateStyle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
        updateStyle()
    }

    // swiftlin:disable:next function_body_length
    func commonInit() {
        backgroundColor = .clear
        layer.zPosition = -1

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentViewConstraints = [
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leftAnchor.constraint(equalTo: leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(contentViewConstraints)
        self.contentView = contentView

        let statusButton = UIButton()
        statusButton.translatesAutoresizingMaskIntoConstraints = false
        statusButton.addTarget(self, action: #selector(statusPressed), for: .touchUpInside)
        statusButton.backgroundColor = .middlePeakBlue
        contentView.addSubview(statusButton)
        statusButtonWidthConstraint = statusButton.widthAnchor.constraint(equalToConstant: 8)
        NSLayoutConstraint.activate([
            statusButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            statusButton.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            statusButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            statusButtonWidthConstraint
        ])
        self.statusButton = statusButton

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .lowPriorityGrey
        contentView.addSubview(label)
        labelTopConstraint = label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6)
        NSLayoutConstraint.activate([
            labelTopConstraint,
            label.leftAnchor.constraint(equalTo: statusButton.rightAnchor, constant: 10)
        ])
        self.label = label
    }

    private func initAlertLabel() {
        _alertLabel = UILabel()
        _alertLabel.translatesAutoresizingMaskIntoConstraints = false
        _alertLabel.font = .copyXSBold
        _alertLabel.textColor = .orangeAccent
        addSubview(_alertLabel)
        NSLayoutConstraint.activate([
            _alertLabel.firstBaselineAnchor.constraint(equalTo: label.firstBaselineAnchor),
            _alertLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10)
        ])
    }

    private func initStatusLabel() {
        _statusLabel = UILabel()
        _statusLabel.translatesAutoresizingMaskIntoConstraints = false
        _statusLabel.font = .copyXSBold
        _statusLabel.text = "BaseField.statusLabel.unconfirmed".localized
        _statusLabel.textAlignment = .right
        _statusLabel.textColor = .orangeAccent
        _statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(_statusLabel)
        NSLayoutConstraint.activate([
            _statusLabel.firstBaselineAnchor.constraint(equalTo: label.firstBaselineAnchor),
            _statusLabel.leftAnchor.constraint(equalTo: label.rightAnchor, constant: 10),
            _statusLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10)
        ])
    }

    private func initDetailLabel() {
        _detailLabel = UILabel()
        _detailLabel.translatesAutoresizingMaskIntoConstraints = false
        _detailLabel.font = .copyXSRegular
        _detailLabel.textColor = .mainGrey
        addSubview(_detailLabel)
        NSLayoutConstraint.activate([
            _detailLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10),
            _detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3)
        ])
    }

    // swiftlint:disable:next function_body_length
    func updateStyle() {
        contentView.backgroundColor = isPlainText ? .clear : .white
        if isPlainText {
            contentView.removeShadow()
        } else {
            contentView.addShadow(withOffset: CGSize(width: 0, height: 2), radius: 3, color: .black, opacity: 0.15)
        }

        switch style {
        case .input:
            label.font = .copyXSBold
            statusButton.backgroundColor = status == .unconfirmed ? UIColor.orangeAccent.withAlphaComponent(0.3) : UIColor.middlePeakBlue
            statusButton.isUserInteractionEnabled = isEditing && status == .unconfirmed
            statusButton.setImage(isEditing && status == .unconfirmed ? UIImage(named: "Unconfirmed") : nil, for: .normal)
            _statusLabel?.isHidden = true
            _alertLabel?.alpha = 1
            if isFirstResponder {
                if status == .none || text?.isEmpty ?? true {
                    statusButtonWidthConstraint.constant = 0
                } else if isEditing && status == .unconfirmed {
                    statusButtonWidthConstraint.constant = 47
                    statusLabel.isHidden = false
                    _alertLabel?.alpha = 0
                } else {
                    statusButtonWidthConstraint.constant = 22
                }
                labelTopConstraint.constant = 8
                contentViewConstraints[1].constant = -8
                contentViewConstraints[2].constant = -8
                layer.zPosition = 0
            } else {
                if status == .none || text?.isEmpty ?? true {
                    statusButtonWidthConstraint.constant = 0
                } else if isEditing && status == .unconfirmed {
                    statusButtonWidthConstraint.constant = 33
                } else {
                    statusButtonWidthConstraint.constant = 8
                }
                labelTopConstraint.constant = 4

                contentViewConstraints[1].constant = 0
                contentViewConstraints[2].constant = 0
                layer.zPosition = -1
            }
        case .onboarding:
            label.font = .copySBold
            statusButtonWidthConstraint.constant = 0
            labelTopConstraint.constant = 8
        }
    }

    @objc func statusPressed() {
        delegate?.formFieldDidConfirmStatus?(self)
        status = .confirmed
        updateStyle()
    }
}
