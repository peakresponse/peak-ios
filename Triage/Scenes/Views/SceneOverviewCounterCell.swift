//
//  SceneOverviewCounterCell.swift
//  Triage
//
//  Created by Francis Li on 5/10/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import UIKit
import PRKit

protocol SceneOverviewCounterCellDelegate: AnyObject {
    func counterCell(_ cell: SceneOverviewCounterCell, didChange value: Int, for priority: TriagePriority?)
}

class SceneOverviewCounterCell: UICollectionViewCell, SceneOverviewCell {
    @IBOutlet weak var counterControl: CounterControl!

    weak var delegate: SceneOverviewCounterCellDelegate?

    var priority: TriagePriority? {
        didSet { updatePriority() }
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        var frame = attributes.frame
        if traitCollection.horizontalSizeClass == .compact {
            frame.size.width = UIScreen.main.bounds.width - 40
        }
        attributes.frame = frame
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

    @IBAction func counterValueChanged(_ sender: CounterControl) {
        delegate?.counterCell(self, didChange: sender.count, for: priority)
    }
}
