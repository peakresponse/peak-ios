//
//  SortSelectorView.swift
//  Triage
//
//  Created by Francis Li on 3/22/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

protocol SortSelectorViewDelegate: NSObject {
    func sortSelectorView(_ view: SortSelectorView, didSelectSort sort: Sort)
}

class SortSelectorView: UIView {    
    @IBOutlet weak var button0: UIButton!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    
    weak var delegate: SortSelectorViewDelegate?
    
    private var buttons: [UIButton] = []
    
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
            button3
        ]
        for sort in Sort.allCases {
            let button = buttons[sort.rawValue]
            button.setTitle(NSLocalizedString("Patient.sort.\(sort.rawValue)", comment: ""), for: .normal)
            button.setBackgroundImage(UIImage.resizableImage(withColor: .natBlue, cornerRadius: 0), for: .highlighted)
            button.setTitleColor(.white, for: .highlighted)
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        }
    }

    @objc func buttonPressed(_ button: UIButton) {
        if let index = buttons.firstIndex(of: button),
            let sort = Sort(rawValue: index) {
            delegate?.sortSelectorView(self, didSelectSort: sort)
        }
        isHidden = true
    }
}
