//
//  BaseField.swift
//  Triage
//
//  Created by Francis Li on 9/4/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

enum FormFieldStatus: String {
    case none, unverified, verified
}

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
}

class BaseField: UIView, Localizable {
    let contentView = UIView()
    var contentViewConstraints: [NSLayoutConstraint]!
    let statusView = UIView()
    var statusViewWidthConstraint: NSLayoutConstraint!
    let label = UILabel()
    var labelTopConstraint: NSLayoutConstraint!
    
    private var _detailLabel: UILabel!
    var detailLabel: UILabel {
        if (_detailLabel == nil) {
            initDetailLabel()
        }
        return _detailLabel
    }
    private var _alertLabel: UILabel!
    var alertLabel: UILabel {
        if (_alertLabel == nil) {
            initAlertLabel()
        }
        return _alertLabel
    }

    var status: FormFieldStatus = .none {
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
    
    func commonInit() {
        backgroundColor = .clear
        layer.zPosition = -1
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .white
        contentView.addShadow(withOffset: CGSize(width: 0, height: 2), radius: 3, color: .black, opacity: 0.15)
        addSubview(contentView)
        contentViewConstraints = [
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leftAnchor.constraint(equalTo: leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(contentViewConstraints)

        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.backgroundColor = .middlePeakBlue
        contentView.addSubview(statusView)

        label.translatesAutoresizingMaskIntoConstraints = false;
        label.textColor = .lowPriorityGrey
        contentView.addSubview(label)

        statusViewWidthConstraint = statusView.widthAnchor.constraint(equalToConstant: 8)
        labelTopConstraint = label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6)

        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor),
            statusView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            statusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            statusViewWidthConstraint,
            labelTopConstraint,
            label.leftAnchor.constraint(equalTo: statusView.rightAnchor, constant: 10)
        ])
    }

    private func initAlertLabel() {
        _alertLabel = UILabel()
        _alertLabel.translatesAutoresizingMaskIntoConstraints = false
        _alertLabel.font = .copyXSBold
        _alertLabel.textColor = .orangeAccent
        addSubview(_alertLabel)
        NSLayoutConstraint.activate([
            _alertLabel.topAnchor.constraint(equalTo: label.topAnchor),
            _alertLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10)
        ])
    }

    private func initDetailLabel() {
        _detailLabel = UILabel()
        _detailLabel.translatesAutoresizingMaskIntoConstraints = false
        _detailLabel.font = .copyXSRegular
        _detailLabel.textColor = .mainGrey
        addSubview(_detailLabel)
        NSLayoutConstraint.activate([
            _detailLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10),
            _detailLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3)
        ])
    }

    func updateStyle() {
        switch style {
        case .input:
            label.font = .copyXSBold
            if isFirstResponder {
                if status == .none {
                    statusViewWidthConstraint.constant = 0
                } else {
                    statusViewWidthConstraint.constant = 22
                }
                labelTopConstraint.constant = 8
                contentViewConstraints[1].constant = -8
                contentViewConstraints[2].constant = -8
                layer.zPosition = 0
            } else {
                if status == .none {
                    statusViewWidthConstraint.constant = 0
                } else {
                    statusViewWidthConstraint.constant = 8
                }
                labelTopConstraint.constant = 4

                contentViewConstraints[1].constant = 0
                contentViewConstraints[2].constant = 0
                layer.zPosition = -1
            }
        case .onboarding:
            label.font = .copySBold
            statusViewWidthConstraint.constant = 0
            labelTopConstraint.constant = 8
        }
    }
}
