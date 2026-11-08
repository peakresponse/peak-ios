//
//  ReportTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/6/26.
//  Copyright © 2026 Francis Li. All rights reserved.
//

import PRKit
import UIKit

class ReportTableViewCell: UITableViewCell {
    weak var containerView: UIStackView!
    weak var checkbox: Checkbox!
    weak var priorityChip: Chip!
    weak var originalPriorityChip: Chip!
    weak var tagLabel: UILabel!
    weak var descLabel: UILabel!
    weak var updatedAtLabel: UILabel!

    var containerViewConstraints: [NSLayoutConstraint] = []
    var tagLabelWidthConstraint: NSLayoutConstraint?
    var priorityWidthConstraint: NSLayoutConstraint?
    var containerViewHeightConstraint: NSLayoutConstraint?
    var originalPriorityChipWidthConstraint: NSLayoutConstraint?
    var descLabelRightViewConstraint: NSLayoutConstraint?
    var descLabelRightPriorityChipConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // swiftlint:disable:next function_body_length
    func commonInit() {
        backgroundColor = .background

        let selectedBackgroundView = UIView()
        selectedBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        selectedBackgroundView.backgroundColor = .highlight
        self.selectedBackgroundView = selectedBackgroundView

        let containerView = UIStackView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.axis = .horizontal
        containerView.alignment = .center
        containerView.spacing = 16
        contentView.addSubview(containerView)
        let containerViewLeftConstraint = containerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
        containerViewLeftConstraint.priority = .defaultHigh
        let containerViewRightConstraint = containerView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16)
        containerViewRightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            containerViewLeftConstraint,
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            containerViewRightConstraint,
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18)
        ])
        self.containerView = containerView

        let checkbox = Checkbox()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.isUserInteractionEnabled = false
        checkbox.label.superview?.isHidden = true
        checkbox.widthAnchor.constraint(equalToConstant: 40).isActive = true
        self.checkbox = checkbox

        let priorityChip = Chip()
        priorityChip.translatesAutoresizingMaskIntoConstraints = false
        priorityChip.isUserInteractionEnabled = false
        priorityChip.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.priorityChip = priorityChip

        let tagLabel = UILabel()
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.font = .h3SemiBold
        tagLabel.textColor = .text
        self.tagLabel = tagLabel

        let originalPriorityChip = Chip()
        originalPriorityChip.translatesAutoresizingMaskIntoConstraints = false
        originalPriorityChip.isUserInteractionEnabled = false
        originalPriorityChip.isHidden = true
        self.originalPriorityChip = originalPriorityChip

        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .h4
        descLabel.textColor = .labelText
        descLabel.numberOfLines = 1
        descLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        self.descLabel = descLabel

        let updatedAtLabel = UILabel()
        updatedAtLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedAtLabel.font = .body14Bold
        updatedAtLabel.textColor = .labelText
        updatedAtLabel.setContentHuggingPriority(.required, for: .horizontal)
        self.updatedAtLabel = updatedAtLabel

        updateLayout()

        let hr = UIView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.backgroundColor = .disabledBorder
        contentView.addSubview(hr)
        NSLayoutConstraint.activate([
            hr.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            hr.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            hr.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hr.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    func constrain(to view: UIView) {
        NSLayoutConstraint.deactivate(containerViewConstraints)
        containerViewConstraints.removeAll()
        containerViewConstraints.append(contentsOf: [
            containerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        NSLayoutConstraint.activate(containerViewConstraints)
    }

    func configure(report: Report?, index: Int, selected: Bool) {
        guard let report = report else { return }

        checkbox.isChecked = selected

        if let pin = report.pin, !pin.isEmpty {
            tagLabel.text = "#\(pin)"
        }

        let priority = TriagePriority(rawValue: report.filterPriority ?? -1) ?? .unknown
        priorityChip.color = priority.color
        priorityChip.setTitle(priority.description, for: .normal)

        if priority == .transported {
            let originalPriority = TriagePriority(rawValue: report.patient?.priority ?? -1) ?? .unknown
            originalPriorityChip.color = originalPriority.color
            originalPriorityChip.setTitle(originalPriority.description, for: .normal)
            originalPriorityChip.isHidden = false
            checkbox.isHidden = true

            originalPriorityChipWidthConstraint?.isActive = true
            descLabelRightViewConstraint?.isActive = false
            descLabelRightPriorityChipConstraint?.isActive = true
        } else {
            originalPriorityChip.isHidden = true

            originalPriorityChipWidthConstraint?.isActive = false
            descLabelRightPriorityChipConstraint?.isActive = false
            descLabelRightViewConstraint?.isActive = true

            checkbox.isHidden = false
        }

        descLabel.text = report.description
        updatedAtLabel.text = report.updatedAt?.asRelativeString() ?? " "
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateLayout()
        }
    }

    // swiftlint:disable:next function_body_length
    func updateLayout() {
        for view in containerView.arrangedSubviews {
            view.removeFromSuperview()
        }
        priorityChip.removeFromSuperview()
        tagLabel.removeFromSuperview()
        originalPriorityChip.removeFromSuperview()
        descLabel.removeFromSuperview()
        updatedAtLabel.removeFromSuperview()
        tagLabelWidthConstraint?.isActive = false
        tagLabelWidthConstraint = nil
        priorityWidthConstraint?.isActive = false
        priorityWidthConstraint = nil
        containerViewHeightConstraint?.isActive = false
        containerViewHeightConstraint = nil
        originalPriorityChipWidthConstraint?.isActive = false
        originalPriorityChipWidthConstraint = nil
        descLabelRightViewConstraint?.isActive = false
        descLabelRightViewConstraint = nil
        descLabelRightPriorityChipConstraint?.isActive = false
        descLabelRightPriorityChipConstraint = nil

        containerView.addArrangedSubview(checkbox)
        if traitCollection.horizontalSizeClass == .regular {
            var view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(tagLabel)
            view.addSubview(descLabel)
            view.addSubview(updatedAtLabel)
            NSLayoutConstraint.activate([
                tagLabel.topAnchor.constraint(equalTo: view.topAnchor),
                tagLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
                view.bottomAnchor.constraint(equalTo: tagLabel.bottomAnchor),
                descLabel.leftAnchor.constraint(equalTo: tagLabel.rightAnchor, constant: 16),
                descLabel.centerYAnchor.constraint(equalTo: tagLabel.centerYAnchor),
                updatedAtLabel.leftAnchor.constraint(equalTo: descLabel.rightAnchor, constant: 16),
                updatedAtLabel.centerYAnchor.constraint(equalTo: descLabel.centerYAnchor),
                view.rightAnchor.constraint(equalTo: updatedAtLabel.rightAnchor)
            ])
            containerView.addArrangedSubview(view)

            let stackView = UIStackView()
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.alignment = .fill
            stackView.spacing = 4
            stackView.addArrangedSubview(priorityChip)
            stackView.addArrangedSubview(originalPriorityChip)

            view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: view.topAnchor),
                stackView.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor),
                stackView.rightAnchor.constraint(equalTo: view.rightAnchor),
                view.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
            ])
            containerView.addArrangedSubview(view)

            tagLabelWidthConstraint = tagLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor,
                                                                      multiplier: 0.25,
                                                                      constant: -8)
            tagLabelWidthConstraint?.isActive = true
            priorityWidthConstraint = view.widthAnchor.constraint(equalTo: containerView.widthAnchor,
                                                                  multiplier: 0.25,
                                                                  constant: -8)
            priorityWidthConstraint?.isActive = true
            containerViewHeightConstraint = containerView.heightAnchor.constraint(equalTo: priorityChip.heightAnchor,
                                                                                  multiplier: 2,
                                                                                  constant: 4)
            containerViewHeightConstraint?.isActive = true
        } else {
            let col = UIStackView()
            col.translatesAutoresizingMaskIntoConstraints = false
            col.axis = .vertical
            col.spacing = 4
            col.alignment = .fill
            containerView.addArrangedSubview(col)

            var view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            col.addArrangedSubview(view)

            view.addSubview(priorityChip)
            NSLayoutConstraint.activate([
                priorityChip.topAnchor.constraint(equalTo: view.topAnchor),
                priorityChip.rightAnchor.constraint(equalTo: view.rightAnchor),
                view.bottomAnchor.constraint(equalTo: priorityChip.bottomAnchor)
            ])

            view.addSubview(tagLabel)
            NSLayoutConstraint.activate([
                tagLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
                tagLabel.centerYAnchor.constraint(equalTo: priorityChip.centerYAnchor),
                tagLabel.rightAnchor.constraint(lessThanOrEqualTo: priorityChip.leftAnchor, constant: -10)
            ])

            view = UIView()
            col.addArrangedSubview(view)
            view.addSubview(originalPriorityChip)

            originalPriorityChipWidthConstraint = originalPriorityChip.widthAnchor.constraint(equalTo: priorityChip.widthAnchor)
            NSLayoutConstraint.activate([
                originalPriorityChip.topAnchor.constraint(equalTo: view.topAnchor),
                originalPriorityChip.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
            originalPriorityChipWidthConstraint?.isActive = !originalPriorityChip.isHidden

            view.addSubview(descLabel)
            descLabelRightViewConstraint = descLabel.rightAnchor.constraint(equalTo: view.rightAnchor)
            descLabelRightViewConstraint?.isActive = originalPriorityChip.isHidden
            descLabelRightPriorityChipConstraint = descLabel.rightAnchor.constraint(lessThanOrEqualTo: originalPriorityChip.leftAnchor, constant: -10)
            descLabelRightPriorityChipConstraint?.isActive = !originalPriorityChip.isHidden
            NSLayoutConstraint.activate([
                descLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
                descLabel.topAnchor.constraint(equalTo: view.topAnchor),
                view.bottomAnchor.constraint(equalTo: descLabel.bottomAnchor)
            ])

            col.addArrangedSubview(updatedAtLabel)
        }
    }
}
