//
//  ReportsCountsHeaderView.swift
//  Triage
//
//  Created by Francis Li on 11/8/23.
//  Copyright © 2023 Francis Li. All rights reserved.
//

import UIKit

class ReportsCountsHeaderView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .red
    }
}
