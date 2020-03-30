//
//  TableViewHeaderView.swift
//  Triage
//
//  Created by Francis Li on 3/20/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class TableViewHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var customBackgroundView: UIView!
    @IBOutlet weak var customLabel: UILabel!

    override var textLabel: UILabel? {
        get { return nil }
        set {}
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        customBackgroundView.layer.cornerRadius = 5
        customBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
}
