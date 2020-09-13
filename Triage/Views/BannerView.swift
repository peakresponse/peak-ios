//
//  BannerView.swift
//  Triage
//
//  Created by Francis Li on 9/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class BannerView: UIView {
    weak var label: UILabel!
    
    @IBInspectable var l10nKey: String? {
        get { return nil }
        set { label.l10nKey = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .peakBlue
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 25)
        ])
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copySBold
        label.textColor = .white
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        self.label = label
    }
}

