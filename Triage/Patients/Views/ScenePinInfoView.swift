//
//  ScenePinInfoView.swift
//  Triage
//
//  Created by Francis Li on 10/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation
import UIKit

protocol ScenePinInfoViewDelegate: class {
    func scenePinInfoViewDidEdit(_ view: ScenePinInfoView)
    func scenePinInfoViewDidDelete(_ view: ScenePinInfoView)
    func scenePinInfoViewDidCancel(_ view: ScenePinInfoView)
    func scenePinInfoViewDidSave(_ view: ScenePinInfoView)
    func scenePinInfoView(_ view: ScenePinInfoView, didChangeDesc desc: String)
}

// swiftlint:disable:next type_body_length
class ScenePinInfoView: UIView, FormFieldDelegate {
    weak var separatorView: UIView!
    weak var editButton: UIButton!
    weak var deleteButton: UIButton!
    weak var iconView: RoundImageView!
    weak var nameLabel: UILabel!
    weak var descLabel: UILabel!
    weak var officersLabel: UILabel!

    weak var descField: FormMultilineField!
    weak var changeLabel: UILabel!
    weak var buttonsView: UIView!

    weak var delegate: ScenePinInfoViewDelegate?

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
        backgroundColor = .white
        addShadow(withOffset: CGSize(width: 0, height: 6), radius: 10, color: .mainGrey, opacity: 0.15)

        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .middlePeakBlue
        separatorView.layer.cornerRadius = 2.5
        addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.widthAnchor.constraint(equalToConstant: 50),
            separatorView.heightAnchor.constraint(equalToConstant: 5),
            separatorView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            separatorView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        self.separatorView = separatorView

        let iconView = RoundImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageView.contentMode = .center
        addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 26),
            iconView.rightAnchor.constraint(equalTo: rightAnchor, constant: -22),
            iconView.widthAnchor.constraint(equalToConstant: 50),
            iconView.heightAnchor.constraint(equalToConstant: 50)
        ])
        self.iconView = iconView

        let topStackView = UIStackView()
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        topStackView.axis = .horizontal
        topStackView.alignment = .firstBaseline
        topStackView.distribution = .fillProportionally
        topStackView.spacing = 4
        addSubview(topStackView)
        NSLayoutConstraint.activate([
            topStackView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            topStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            topStackView.rightAnchor.constraint(equalTo: iconView.leftAnchor, constant: -22)
        ])

        let editButton = UIButton(type: .custom)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addTarget(self, action: #selector(editPressed), for: .touchUpInside)
        editButton.isHidden = true
        editButton.setImage(UIImage(named: "Edit"), for: .normal)
        editButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        topStackView.addArrangedSubview(editButton)
        NSLayoutConstraint.activate([
            editButton.widthAnchor.constraint(equalToConstant: 28),
            editButton.heightAnchor.constraint(equalToConstant: 28)
        ])
        self.editButton = editButton

        let deleteButton = UIButton(type: .custom)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deletePressed), for: .touchUpInside)
        deleteButton.isHidden = true
        deleteButton.setImage(UIImage(named: "Trash"), for: .normal)
        deleteButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        topStackView.addArrangedSubview(deleteButton)
        NSLayoutConstraint.activate([
            deleteButton.widthAnchor.constraint(equalToConstant: 28),
            deleteButton.heightAnchor.constraint(equalToConstant: 28)
        ])
        self.deleteButton = deleteButton

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .copyMBold
        nameLabel.textColor = .mainGrey
        nameLabel.numberOfLines = 0
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        topStackView.addArrangedSubview(nameLabel)
        self.nameLabel = nameLabel

        let middleStackView = UIStackView()
        middleStackView.translatesAutoresizingMaskIntoConstraints = false
        middleStackView.axis = .vertical
        middleStackView.spacing = 6
        addSubview(middleStackView)
        NSLayoutConstraint.activate([
            middleStackView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 2),
            middleStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            middleStackView.rightAnchor.constraint(equalTo: iconView.leftAnchor, constant: -22)
        ])

        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .copySRegular
        descLabel.textColor = .mainGrey
        descLabel.numberOfLines = 0
        middleStackView.addArrangedSubview(descLabel)
        self.descLabel = descLabel

        let officersLabel = UILabel()
        officersLabel.translatesAutoresizingMaskIntoConstraints = false
        officersLabel.font = .copySRegular
        officersLabel.textColor = .mainGrey
        officersLabel.numberOfLines = 0
        middleStackView.addArrangedSubview(officersLabel)
        self.officersLabel = officersLabel

        let descField = FormMultilineField()
        descField.delegate = self
        descField.labelText = "NewScenePinView.descField.label".localized
        descField.isHidden = true
        middleStackView.addArrangedSubview(descField)
        NSLayoutConstraint.activate([
            descField.leftAnchor.constraint(equalTo: middleStackView.leftAnchor),
            descField.rightAnchor.constraint(equalTo: iconView.leftAnchor, constant: -22)
        ])
        self.descField = descField

        let bottomStackView = UIStackView()
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomStackView.axis = .vertical
        bottomStackView.alignment = .center
        bottomStackView.spacing = 6
        addSubview(bottomStackView)
        NSLayoutConstraint.activate([
            bottomStackView.topAnchor.constraint(equalTo: middleStackView.bottomAnchor, constant: 8),
            bottomStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            bottomStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -22),
            bottomAnchor.constraint(equalTo: bottomStackView.bottomAnchor, constant: 16)
        ])

        let changeLabel = UILabel()
        changeLabel.translatesAutoresizingMaskIntoConstraints = false
        changeLabel.isHidden = true
        changeLabel.font = .copyXSBold
        changeLabel.text = "ScenePinInfoView.change".localized
        changeLabel.textColor = .peakBlue
        changeLabel.numberOfLines = 0
        bottomStackView.addArrangedSubview(changeLabel)
        self.changeLabel = changeLabel

        let buttonsView = UIView()
        buttonsView.translatesAutoresizingMaskIntoConstraints = false
        buttonsView.isHidden = true
        buttonsView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        bottomStackView.addArrangedSubview(buttonsView)
        NSLayoutConstraint.activate([
            buttonsView.widthAnchor.constraint(equalToConstant: 252)
        ])
        self.buttonsView = buttonsView

        let cancelButton = FormButton(size: .xsmall, style: .lowPriority)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        cancelButton.buttonLabel = "Button.cancel".localized
        buttonsView.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: buttonsView.topAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 122),
            cancelButton.leftAnchor.constraint(equalTo: buttonsView.leftAnchor)
        ])

        let saveButton = FormButton(size: .xsmall, style: .priority)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(savePressed), for: .touchUpInside)
        saveButton.buttonLabel = "Button.save".localized
        buttonsView.addSubview(saveButton)
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: buttonsView.topAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 122),
            saveButton.rightAnchor.constraint(equalTo: buttonsView.rightAnchor),
            buttonsView.bottomAnchor.constraint(equalTo: saveButton.bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // make sure shadow is only on bottom half of view so it doesn't appear on top of search box
        layer.shadowPath = UIBezierPath(rect: CGRect(x: 0, y: bounds.height / 2, width: bounds.width, height: bounds.height / 2)).cgPath
    }

    func configure(from pin: ScenePin, isMGS: Bool) {
        let type = ScenePinType(rawValue: pin.type ?? "")
        if let type = type {
            iconView.isHidden = false
            iconView.image = type.image.scaledBy(1.5)
            iconView.backgroundColor = type.color
        } else {
            iconView.isHidden = true
        }

        editButton.isHidden = !isMGS
        if type == .other {
            nameLabel.text = pin.name
        } else {
            nameLabel.text = type?.description
        }
        if let text = pin.desc?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            descLabel.setBoldPrefixedText(boldFont: .copySBold, prefix: "ScenePinInfoView.desc".localized, text: text)
            descField.text = text
        }
    }

    @objc func editPressed() {
        backgroundColor = .bgBackground
        editButton.isHidden = true
        deleteButton.isHidden = false
        descLabel.isHidden = true
        officersLabel.isHidden = true
        descField.isHidden = false
        changeLabel.isHidden = false
        buttonsView.isHidden = false
        layoutIfNeeded()
        delegate?.scenePinInfoViewDidEdit(self)
    }

    @objc func deletePressed() {
        delegate?.scenePinInfoViewDidDelete(self)
    }

    @objc func cancelPressed() {
        backgroundColor = .white
        editButton.isHidden = false
        deleteButton.isHidden = true
        descLabel.isHidden = false
        officersLabel.isHidden = false
        descField.isHidden = true
        changeLabel.isHidden = true
        buttonsView.isHidden = true
        layoutIfNeeded()
        delegate?.scenePinInfoViewDidCancel(self)
    }

    @objc func savePressed() {
        delegate?.scenePinInfoViewDidSave(self)
    }

    // MARK: - FormFieldDelegate

    func formFieldDidChange(_ field: BaseField) {
        if field == descField {
            delegate?.scenePinInfoView(self, didChangeDesc: field.text ?? "")
        }
    }
}
