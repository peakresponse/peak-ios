//
//  FacilityView.swift
//  Triage
//
//  Created by Francis Li on 3/3/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import PRKit
import UIKit

class RingdownFacilityCountView: UIView {
    weak var label: UILabel!
    weak var countLabel: UILabel!

    var labelText: String? {
        get { return label.text }
        set { label.text = newValue }
    }

    var countText: String? {
        get { return countLabel.text }
        set { countLabel.text = newValue }
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
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .h4SemiBold
        label.textColor = .base500
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.leftAnchor.constraint(equalTo: leftAnchor),
            bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 4)
        ])
        self.label = label

        let countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = .h4SemiBold
        countLabel.textColor = .base800
        addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: label.topAnchor),
            countLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -4),
            countLabel.leftAnchor.constraint(greaterThanOrEqualTo: label.rightAnchor, constant: 4),
            countLabel.bottomAnchor.constraint(equalTo: label.bottomAnchor)
        ])
        self.countLabel = countLabel
    }
}

protocol RingdownFacilityViewDelegate: AnyObject {
    func ringdownFacilityView(_ view: RingdownFacilityView, didSelect isSelected: Bool)
    func ringdownFacilityView(_ view: RingdownFacilityView, didChangeEta eta: String?)
}

class RingdownFacilityView: UIView, PRKit.FormFieldDelegate {
    weak var selectButton: PRKit.Button!
    weak var arrivalField: PRKit.TextField!
    weak var nameLabel: UILabel!
    weak var updatedAtLabel: UILabel!
    weak var statsStackView: UIStackView!
    var statCountViews: [RingdownFacilityCountView] = []
    weak var notesRule: PixelRuleView!
    weak var notesLabel: UILabel!

    weak var delegate: RingdownFacilityViewDelegate?

    var isSelected: Bool = false {
        didSet {
            arrivalField.isHidden = !isSelected
            selectButton.alpha = isSelected ? 0 : 1
            if isSelected {
                _ = arrivalField.becomeFirstResponder()
            } else {
                arrivalField.text = nil
            }
        }
    }

    var nameText: String? {
        get { return nameLabel.text }
        set { nameLabel.text = newValue }
    }

    func setUpdatedAt(_ date: Date?) {
        updatedAtLabel.text = date?.asTimeDateString() ?? "-"
    }

    var notesText: String? {
        get { return notesLabel.text }
        set { notesLabel.text = newValue }
    }

    var arrivalText: String? {
        get { return arrivalField.text }
        set { arrivalField.text = newValue }
    }

    override var inputAccessoryView: UIView? {
        get { return arrivalField.inputAccessoryView }
        set { arrivalField.inputAccessoryView = newValue }
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
        let selectButton = PRKit.Button()
        selectButton.style = .secondary
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.setTitle("Button.select".localized, for: .normal)
        selectButton.addTarget(self, action: #selector(selectPressed), for: .touchUpInside)
        addSubview(selectButton)
        NSLayoutConstraint.activate([
            selectButton.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            selectButton.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        self.selectButton = selectButton

        let arrivalField = PRKit.TextField()
        arrivalField.translatesAutoresizingMaskIntoConstraints = false
        arrivalField.delegate = self
        arrivalField.labelText = "RingdownFacilityView.eta".localized
        arrivalField.unitText = "RingdownFacilityView.eta.mins".localized
        arrivalField.attributeType = .integer
        arrivalField.isHidden = true
        addSubview(arrivalField)
        NSLayoutConstraint.activate([
            arrivalField.topAnchor.constraint(equalTo: selectButton.topAnchor),
            arrivalField.rightAnchor.constraint(equalTo: selectButton.rightAnchor),
            arrivalField.leftAnchor.constraint(equalTo: selectButton.leftAnchor)
        ])
        self.arrivalField = arrivalField

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .h3SemiBold
        nameLabel.textColor = .base800
        addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: selectButton.topAnchor),
            nameLabel.leftAnchor.constraint(equalTo: leftAnchor),
            nameLabel.rightAnchor.constraint(lessThanOrEqualTo: selectButton.leftAnchor, constant: -16)
        ])
        self.nameLabel = nameLabel

        let updatedAtLabel = UILabel()
        updatedAtLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedAtLabel.font = .body14Bold
        updatedAtLabel.textColor = .base500
        addSubview(updatedAtLabel)
        NSLayoutConstraint.activate([
            updatedAtLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            updatedAtLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            updatedAtLabel.rightAnchor.constraint(lessThanOrEqualTo: selectButton.leftAnchor, constant: -16)
        ])
        self.updatedAtLabel = updatedAtLabel

        let statsStackView = UIStackView()
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.axis = .vertical
        addSubview(statsStackView)
        NSLayoutConstraint.activate([
            statsStackView.topAnchor.constraint(equalTo: updatedAtLabel.bottomAnchor, constant: 16),
            statsStackView.leftAnchor.constraint(equalTo: updatedAtLabel.leftAnchor),
            statsStackView.widthAnchor.constraint(equalToConstant: 180)
        ])
        self.statsStackView = statsStackView

        var countView: RingdownFacilityCountView
        var hr: PixelRuleView

        countView = RingdownFacilityCountView()
        countView.translatesAutoresizingMaskIntoConstraints = false
        countView.labelText = "RingdownFacilityView.erBeds".localized
        statsStackView.addArrangedSubview(countView)
        statCountViews.append(countView)

        hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        statsStackView.addArrangedSubview(hr)

        countView = RingdownFacilityCountView()
        countView.translatesAutoresizingMaskIntoConstraints = false
        countView.labelText = "RingdownFacilityView.psychBeds".localized
        statsStackView.addArrangedSubview(countView)
        statCountViews.append(countView)

        hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        statsStackView.addArrangedSubview(hr)

        countView = RingdownFacilityCountView()
        countView.translatesAutoresizingMaskIntoConstraints = false
        countView.labelText = "RingdownFacilityView.enroute".localized
        statsStackView.addArrangedSubview(countView)
        statCountViews.append(countView)

        hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        statsStackView.addArrangedSubview(hr)

        countView = RingdownFacilityCountView()
        countView.translatesAutoresizingMaskIntoConstraints = false
        countView.labelText = "RingdownFacilityView.waiting".localized
        statsStackView.addArrangedSubview(countView)
        statCountViews.append(countView)

        hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        hr.isHidden = true
        statsStackView.addArrangedSubview(hr)
        self.notesRule = hr

        let notesLabel = UILabel()
        notesLabel.translatesAutoresizingMaskIntoConstraints = false
        notesLabel.font = .h4SemiBold
        notesLabel.textColor = .brandSecondary800
        notesLabel.numberOfLines = 0
        notesLabel.isHidden = true
        addSubview(notesLabel)
        NSLayoutConstraint.activate([
            notesLabel.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 4),
            notesLabel.leftAnchor.constraint(equalTo: statsStackView.leftAnchor),
            notesLabel.rightAnchor.constraint(equalTo: selectButton.rightAnchor),
            bottomAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 40)
        ])
        self.notesLabel = notesLabel
    }

    func update(from update: HospitalStatusUpdate) {
        nameText = update.name
        setUpdatedAt(update.updatedAt)

        statCountViews[0].countText = update.openEdBedCount != nil ? "\(update.openEdBedCount ?? 0)" : "-"
        statCountViews[1].countText = update.openPsychBedCount != nil ? "\(update.openPsychBedCount ?? 0)" : "-"
        statCountViews[2].countText = update.ambulancesEnRoute != nil ? "\(update.ambulancesEnRoute ?? 0)" : "-"
        statCountViews[3].countText = update.ambulancesOffloading != nil ? "\(update.ambulancesOffloading ?? 0)" : "-"

        if let notes = update.notes {
            notesLabel.text = notes
            notesLabel.isHidden = false
            notesRule.isHidden = false
        } else {
            notesLabel.text = nil
            notesLabel.isHidden = true
            notesRule.isHidden = true
        }
    }

    @objc func selectPressed() {
        isSelected = true
        delegate?.ringdownFacilityView(self, didSelect: isSelected)
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        if let field = component as? PRKit.FormField {
            if field.text?.isEmpty ?? true {
                if !field.isFirstResponder && isSelected {
                    isSelected = false
                    delegate?.ringdownFacilityView(self, didSelect: isSelected)
                }
            }
            delegate?.ringdownFacilityView(self, didChangeEta: field.text?.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    func formFieldDidEndEditing(_ field: PRKit.FormField) {
        if field.text?.isEmpty ?? true {
            if isSelected {
                isSelected = false
                delegate?.ringdownFacilityView(self, didSelect: isSelected)
            }
        }
    }
}
