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
        label.textColor = .labelText
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
        countLabel.textColor = .text
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

    var id: String?

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
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .h3SemiBold
        nameLabel.textColor = .text
        addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            nameLabel.leftAnchor.constraint(equalTo: leftAnchor),
            nameLabel.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        self.nameLabel = nameLabel

        let updatedAtLabel = UILabel()
        updatedAtLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedAtLabel.font = .body14Bold
        updatedAtLabel.textColor = .labelText
        addSubview(updatedAtLabel)
        NSLayoutConstraint.activate([
            updatedAtLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            updatedAtLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            updatedAtLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor)
        ])
        self.updatedAtLabel = updatedAtLabel

        let selectButton = PRKit.Button()
        selectButton.style = .secondary
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.setTitle("Button.select".localized, for: .normal)
        selectButton.addTarget(self, action: #selector(selectPressed), for: .touchUpInside)
        addSubview(selectButton)
        NSLayoutConstraint.activate([
            selectButton.topAnchor.constraint(equalTo: updatedAtLabel.bottomAnchor, constant: 16),
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

        let statsStackView = UIStackView()
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.axis = .vertical
        addSubview(statsStackView)
        let widthConstraint = statsStackView.widthAnchor.constraint(equalToConstant: 180)
        widthConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            statsStackView.topAnchor.constraint(equalTo: selectButton.topAnchor),
            statsStackView.leftAnchor.constraint(equalTo: updatedAtLabel.leftAnchor),
            widthConstraint,
            statsStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 180),
            statsStackView.rightAnchor.constraint(lessThanOrEqualTo: selectButton.leftAnchor, constant: -4)
        ])
        self.statsStackView = statsStackView

        var countView: RingdownFacilityCountView

        countView = addStatCountView()
        countView.labelText = "RingdownFacilityView.erBeds".localized

        _ = addStatCountHorizontalRule()

        countView = addStatCountView()
        countView.labelText = "RingdownFacilityView.psychBeds".localized

        _ = addStatCountHorizontalRule()

        countView = addStatCountView()
        countView.labelText = "RingdownFacilityView.enroute".localized

        _ = addStatCountHorizontalRule()

        countView = addStatCountView()
        countView.labelText = "RingdownFacilityView.waiting".localized

        self.notesRule = addStatCountHorizontalRule()

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

    func addStatCountView() -> RingdownFacilityCountView {
        let countView = RingdownFacilityCountView()
        countView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.addArrangedSubview(countView)
        statCountViews.append(countView)
        return countView
    }

    func addStatCountHorizontalRule() -> PixelRuleView {
        let hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        statsStackView.addArrangedSubview(hr)
        return hr
    }

    func configureStatCountViews(customInventory: [String]? = nil) {
        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let customInventory = customInventory {
            for (i, label) in customInventory.enumerated() {
                if i < statCountViews.count {
                    statCountViews[i].labelText = label
                    statsStackView.addArrangedSubview(statCountViews[i])
                } else {
                    let statCountView = addStatCountView()
                    statCountView.labelText = label
                }
                _ = addStatCountHorizontalRule()
            }
            for (i, label) in ["RingdownFacilityView.enroute", "RingdownFacilityView.waiting"].enumerated() {
                if (i + customInventory.count) < statCountViews.count {
                    statCountViews[i + customInventory.count].labelText = label.localized
                    statsStackView.addArrangedSubview(statCountViews[i + customInventory.count])
                } else {
                    let statCountView = addStatCountView()
                    statCountView.labelText = label.localized
                }
                _ = addStatCountHorizontalRule()
            }
        } else {
            for i in 0..<4 {
                statCountViews[i].labelText = ["RingdownFacilityView.erBeds", "RingdownFacilityView.psychBeds", "RingdownFacilityView.enroute", "RingdownFacilityView.waiting"][i].localized
                statsStackView.addArrangedSubview(statCountViews[i])
                _ = addStatCountHorizontalRule()
            }
        }
        statsStackView.removeArrangedSubview(statsStackView.arrangedSubviews.last!)
        statsStackView.addArrangedSubview(self.notesRule)
    }

    func update(from update: HospitalStatusUpdate) {
        nameText = update.name
        setUpdatedAt(update.updatedAt)

        if update.id != id {
            configureStatCountViews(customInventory: update.customInventory)
            id = update.id
        }

        if let customInventory = update.customInventory, customInventory.count > 0 {
            if let customInventoryCount = update.customInventoryCount {
                for (i, count) in customInventoryCount.enumerated() {
                    statCountViews[i].countText = "\(count)"
                }
            }
            statCountViews[customInventory.count].countText = update.ambulancesEnRoute != nil ? "\(update.ambulancesEnRoute ?? 0)" : "-"
            statCountViews[customInventory.count + 1].countText = update.ambulancesOffloading != nil ? "\(update.ambulancesOffloading ?? 0)" : "-"
        } else {
            statCountViews[0].countText = update.openEdBedCount != nil ? "\(update.openEdBedCount ?? 0)" : "-"
            statCountViews[1].countText = update.openPsychBedCount != nil ? "\(update.openPsychBedCount ?? 0)" : "-"
            statCountViews[2].countText = update.ambulancesEnRoute != nil ? "\(update.ambulancesEnRoute ?? 0)" : "-"
            statCountViews[3].countText = update.ambulancesOffloading != nil ? "\(update.ambulancesOffloading ?? 0)" : "-"
        }

        if let notes = update.notes, !notes.isEmpty {
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
