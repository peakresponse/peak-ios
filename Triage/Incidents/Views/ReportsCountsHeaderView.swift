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

class ReportsCountsHeaderView: UICollectionReusableView {
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
        countsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countsView)
        NSLayoutConstraint.activate([
            countsView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            countsView.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
            countsView.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
            bottomAnchor.constraint(equalTo: countsView.bottomAnchor, constant: 10)
        ])
    }

    func configure(from results: Results<Report>?) {
        countsView.setTotalCount(results?.count ?? 0)
        for priority in TriagePriority.allCases {
            if priority == .unknown {
                break
            }
            let count = results?.filter("filterPriority=%d", priority.rawValue).count ?? 0
            countsView.setCount(count, for: priority)
        }
    }
}
