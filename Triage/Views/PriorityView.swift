//
//  PriorityView.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

@objc protocol PriorityViewDelegate {
    @objc optional func priorityView(_ view: PriorityView, didSelect priority: Int)
}

class PriorityView: UIView {
    @IBOutlet weak var button0: UIButton!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!
    weak var delegate: PriorityViewDelegate?
    var buttons: [UIButton] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        loadNib()
        buttons = [
            button0,
            button1,
            button2,
            button3,
            button4
        ]
        for (index, button) in buttons.enumerated() {
            button.setTitle(NSLocalizedString("Patient.priority.\(index)", comment: ""), for: .normal)
            button.setTitleColor(PRIORITY_LABEL_COLORS[index], for: .normal)
            button.backgroundColor = PRIORITY_COLORS[index]
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        }
    }
    
    @objc func buttonPressed(_ button: UIButton) {
        if let priority = buttons.firstIndex(of: button) {
            delegate?.priorityView?(self, didSelect: priority)
        }
    }
}
