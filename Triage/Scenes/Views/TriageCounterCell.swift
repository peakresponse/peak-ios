//
//  TriageCounterCell.swift
//  Triage
//
//  Created by Francis Li on 5/10/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit
import PRKit

protocol TriageCounterCellDelegate: AnyObject {
    func counterCell(_ cell: TriageCounterCell, didChange value: Int, for priority: TriagePriority?)
}

class TriageCounterCell: UICollectionViewCell {
    weak var counterControl: CounterControl!

    weak var delegate: TriageCounterCellDelegate?

    var priority: TriagePriority? {
        didSet { updatePriority() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commonInit() {
        let counterControl = CounterControl()
        counterControl.translatesAutoresizingMaskIntoConstraints = false
        counterControl.addTarget(self, action: #selector(counterValueChanged(_:)), for: .valueChanged)
        contentView.addSubview(counterControl)
        NSLayoutConstraint.activate([
            counterControl.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            counterControl.leftAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leftAnchor),
            counterControl.rightAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.rightAnchor),
            counterControl.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
        ])
        self.counterControl = counterControl
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        var view = superview
        while !(view?.isKind(of: UICollectionView.self) ?? true) {
            view = view?.superview
        }
        if let bounds = view?.bounds {
            attributes.frame.size.width = bounds.size.width
            if priority != nil && traitCollection.horizontalSizeClass == .regular,
               let layout = (view as? UICollectionView)?.collectionViewLayout as? UICollectionViewFlowLayout {
                attributes.frame.size.width = floor((bounds.size.width - layout.minimumInteritemSpacing) / 2)
            }
        }
        return attributes
    }

    func updatePriority() {
        if let priority = priority {
            counterControl.color = priority.color
            counterControl.labelText = priority.description
        } else {
            counterControl.color = .base500
            counterControl.labelText = "SceneOverviewCounterCell.totalLabel".localized
        }
    }

    func configure(from scene: Scene) {
        if counterControl.isChanged {
            return
        }
        if let priority = priority {
            counterControl.count = scene.approxPriorityPatientsCounts?[priority.rawValue] ?? 0
            counterControl.isEnabled = scene.isResponder(userId: AppSettings.userId)
        } else {
            var count = 0
            if let approxPriorityPatientsCounts = scene.approxPriorityPatientsCounts {
                count = approxPriorityPatientsCounts[0..<5].reduce(count, { return $0 + $1 })
            }
            counterControl.count = count
            counterControl.isEnabled = false
        }
    }

    @objc func counterValueChanged(_ sender: CounterControl) {
        delegate?.counterCell(self, didChange: sender.count, for: priority)
    }
}
