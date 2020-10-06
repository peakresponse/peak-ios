//
//  PatientSectionTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 10/4/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class SectionInfoTableViewCell: UITableViewCell {
    weak var label: UILabel!
    weak var button: FormButton!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copySBold
        label.textColor = .mainGrey
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -22)
        ])
        self.label = label

        let button = FormButton(size: .xxsmall, style: .lowPriority)
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 5),
            button.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            contentView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 5)
        ])
        self.button = button
    }
}
