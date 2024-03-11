//
//  ReportsCountsHeaderView.swift
//  Triage
//
//  Created by Francis Li on 11/8/23.
//  Copyright © 2023 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift
import UIKit

protocol ReportsCountsHeaderViewDelegate: AnyObject {
    func reportsCountsHeaderView(_ view: ReportsCountsHeaderView, didSelect priority: TriagePriority?)
}

class ReportsCountsHeaderView: UICollectionReusableView, TriageCountsDelegate {
    weak var delegate: ReportsCountsHeaderViewDelegate?
    var countsView: TriageCounts!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .white

        countsView = TriageCounts()
        countsView.delegate = self
        countsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countsView)
        NSLayoutConstraint.activate([
            countsView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            countsView.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
            countsView.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
            bottomAnchor.constraint(equalTo: countsView.bottomAnchor, constant: 10)
        ])

        countsView.totalButton.isSelected = true
    }

    func configure(from results: Results<Report>?) {
        countsView.setTotalCount(results?.count ?? 0)
        for priority in TriagePriority.allCases {
            if priority == .transported {
                let count = results?.filter("filterPriority=%d", priority.rawValue).count ?? 0
                countsView.setCount(count, for: priority)
                break
            }
            let count = results?.filter("patient.priority=%d", priority.rawValue).count ?? 0
            countsView.setCount(count, for: priority)
        }
    }

    // MARK: - TriageCountsDelegate

    func triageCounts(_ view: TriageCounts, didPress button: Button, with priority: TriagePriority) {
        countsView.totalButton.isSelected = false
        for button in countsView.priorityButtons {
            button.isSelected = false
        }
        button.isSelected = true
        delegate?.reportsCountsHeaderView(self, didSelect: priority)
    }

    func triageCounts(_ view: TriageCounts, didPressTotal button: Button) {
        for button in countsView.priorityButtons {
            button.isSelected = false
        }
        button.isSelected = true
        delegate?.reportsCountsHeaderView(self, didSelect: nil)
    }
}
