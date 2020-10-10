//
//  UserTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 9/30/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    weak var userView: UserView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .bgBackground
        self.backgroundView = backgroundView

        let userView = UserView()
        userView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userView)
        NSLayoutConstraint.activate([
            userView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            userView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            userView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -22),
            contentView.bottomAnchor.constraint(equalTo: userView.bottomAnchor, constant: 5)
        ])
        self.userView = userView
    }

    func configure(from responder: Responder, isMGS: Bool = false) {
        userView.configure(from: responder, isMGS: isMGS)
    }
}
