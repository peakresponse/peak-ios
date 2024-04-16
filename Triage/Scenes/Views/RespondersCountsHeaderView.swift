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

class RespondersCountsHeaderView: UICollectionReusableView {
    weak var stackView: UIStackView!
    weak var enrouteButton: Button!
    weak var arrivedButton: Button!
    weak var totalButton: Button!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
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
        enrouteButton.size = .small
        enrouteButton.style = .secondary
        enrouteButton.titleLabel?.font = .h4SemiBold
        enrouteButton.contentEdgeInsets = UIEdgeInsets(top: 13, left: 2, bottom: 13, right: 2)
        stackView.addArrangedSubview(enrouteButton)
        self.enrouteButton = enrouteButton

        let arrivedButton = Button()
        arrivedButton.size = .small
        arrivedButton.style = .secondary
        arrivedButton.titleLabel?.font = .h4SemiBold
        arrivedButton.contentEdgeInsets = UIEdgeInsets(top: 13, left: 2, bottom: 13, right: 2)
        stackView.addArrangedSubview(arrivedButton)
        self.arrivedButton = arrivedButton

        let totalButton = Button()
        totalButton.size = .small
        totalButton.style = .secondary
        totalButton.titleLabel?.font = .h4SemiBold
        totalButton.contentEdgeInsets = UIEdgeInsets(top: 13, left: 2, bottom: 13, right: 2)
        stackView.addArrangedSubview(totalButton)
        self.totalButton = totalButton
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
