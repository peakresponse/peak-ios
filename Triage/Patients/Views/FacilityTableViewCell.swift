//
//  FacilityTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 4/7/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class FacilityTableViewCell: UITableViewCell {
    let facilityView = FacilityView()
    let containerView = UIView()
    let headerView = UIView()
    let nameLabel = UILabel()
    let distanceLabel = UILabel()
    let addressLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        selectionStyle = .none
        backgroundColor = .clear
        facilityView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(facilityView)
        NSLayoutConstraint.activate([
            facilityView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            facilityView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            facilityView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -22),
            facilityView.heightAnchor.constraint(equalToConstant: 78),
            contentView.bottomAnchor.constraint(equalTo: facilityView.bottomAnchor, constant: 5)
        ])
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        facilityView.setSelected(highlighted)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        facilityView.setSelected(selected)
    }

    func configure(from facility: Facility) {
        facilityView.configure(from: facility)
    }

    func configure(from agency: Agency) {
        facilityView.configure(from: agency)
    }
}
