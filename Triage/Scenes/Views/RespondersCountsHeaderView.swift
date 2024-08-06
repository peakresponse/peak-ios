//
//  RespondersCountsHeaderView.swift
//  Triage
//
//  Created by Francis Li on 4/15/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import RealmSwift
import UIKit

@objc protocol RespondersCountsHeaderViewDelegate {
    @objc optional func respondersCountsHeaderView(_ view: RespondersCountsHeaderView, didPressArrived button: Button)
    @objc optional func respondersCountsHeaderView(_ view: RespondersCountsHeaderView, didPressEnroute button: Button)
    @objc optional func respondersCountsHeaderView(_ view: RespondersCountsHeaderView, didPressTotal button: Button)
}

class RespondersCountsHeaderView: UICollectionReusableView {
    weak var stackView: UIStackView!
    weak var enrouteButton: Button!
    weak var arrivedButton: Button!
    weak var totalButton: Button!

    weak var delegate: RespondersCountsHeaderViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        backgroundColor = .background

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10)
        ])
        self.stackView = stackView

        let enrouteButton = Button()
        configure(button: enrouteButton, labelColor: TriagePriority.delayed.labelColor, color: TriagePriority.delayed.color, lightenedColor: TriagePriority.delayed.lightenedColor)
        stackView.addArrangedSubview(enrouteButton)
        self.enrouteButton = enrouteButton

        let arrivedButton = Button()
        configure(button: arrivedButton, labelColor: TriagePriority.minimal.labelColor, color: TriagePriority.minimal.color, lightenedColor: TriagePriority.minimal.lightenedColor)
        stackView.addArrangedSubview(arrivedButton)
        self.arrivedButton = arrivedButton

        let totalButton = Button()
        configure(button: totalButton, labelColor: .base800, color: .base300, lightenedColor: .white)
        totalButton.isSelected = true
        stackView.addArrangedSubview(totalButton)
        self.totalButton = totalButton
    }

    func configure(button: Button, labelColor: UIColor, color: UIColor, lightenedColor: UIColor) {
        button.size = .small
        button.style = .secondary
        button.titleLabel?.font = .h4SemiBold
        button.contentEdgeInsets = UIEdgeInsets(top: 13, left: 2, bottom: 13, right: 2)
        button.setTitleColor(.base800, for: .normal)
        button.setTitleColor(labelColor, for: .highlighted)
        button.setTitleColor(labelColor, for: .selected)
        button.setTitleColor(labelColor, for: [.selected, .highlighted])
        button.setBackgroundImage(.resizableImage(withColor: lightenedColor, cornerRadius: 8,
                                                  borderColor: color, borderWidth: 2), for: .normal)
        button.setBackgroundImage(.resizableImage(withColor: color, cornerRadius: 8,
                                                  borderColor: color, borderWidth: 2), for: .highlighted)
        button.setBackgroundImage(.resizableImage(withColor: color, cornerRadius: 8,
                                                  borderColor: color, borderWidth: 2), for: .selected)
        button.setBackgroundImage(.resizableImage(withColor: color, cornerRadius: 8,
                                                  borderColor: color, borderWidth: 2), for: [.selected, .highlighted])
        button.setBackgroundImage(.resizableImage(withColor: lightenedColor, cornerRadius: 8,
                                                  borderColor: lightenedColor, borderWidth: 2), for: .disabled)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
    }

    @objc func buttonPressed(_ sender: Button) {
        if sender != totalButton && !sender.isSelected {
            if sender == enrouteButton {
                arrivedButton.isSelected = false
                enrouteButton.isSelected = true
                totalButton.isSelected = false
                delegate?.respondersCountsHeaderView?(self, didPressEnroute: sender)
            } else if sender == arrivedButton {
                arrivedButton.isSelected = true
                enrouteButton.isSelected = false
                totalButton.isSelected = false
                delegate?.respondersCountsHeaderView?(self, didPressArrived: sender)
            }
        } else {
            arrivedButton.isSelected = false
            enrouteButton.isSelected = false
            totalButton.isSelected = true
            delegate?.respondersCountsHeaderView?(self, didPressTotal: sender)
        }
    }

    func configure(from results: Results<Responder>?) {
        let totalCount = results?.count ?? 0
        let enrouteCount = results?.filter("arrivedAt=NULL").count ?? 0
        let arrivedCount = results?.filter("arrivedAt<>NULL").count ?? 0
        enrouteButton.setTitle(String(format: "RespondersCountsHeaderView.enroute".localized, enrouteCount), for: .normal)
        arrivedButton.setTitle(String(format: "RespondersCountsHeaderView.arrived".localized, arrivedCount), for: .normal)
        totalButton.setTitle(String(format: "RespondersCountsHeaderView.total".localized, totalCount), for: .normal)
    }
}
