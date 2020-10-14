//
//  ScenePinInfoView.swift
//  Triage
//
//  Created by Francis Li on 10/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation
import UIKit

class ScenePinInfoView: UIView {
    weak var separatorView: UIView!
    weak var iconView: RoundImageView!
    weak var nameLabel: UILabel!
    weak var descLabel: UILabel!
    weak var officersLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // swiftlint:disable:next function_body_length
    private func commonInit() {
        backgroundColor = .white
        addShadow(withOffset: CGSize(width: 0, height: 6), radius: 10, color: .mainGrey, opacity: 0.15)

        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .middlePeakBlue
        separatorView.layer.cornerRadius = 2.5
        addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.widthAnchor.constraint(equalToConstant: 50),
            separatorView.heightAnchor.constraint(equalToConstant: 5),
            separatorView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            separatorView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        self.separatorView = separatorView

        let iconView = RoundImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageView.contentMode = .center
        addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 26),
            iconView.rightAnchor.constraint(equalTo: rightAnchor, constant: -22),
            iconView.widthAnchor.constraint(equalToConstant: 50),
            iconView.heightAnchor.constraint(equalToConstant: 50)
        ])
        self.iconView = iconView

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .copyMBold
        nameLabel.textColor = .mainGrey
        nameLabel.numberOfLines = 0
        addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 26),
            nameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            nameLabel.rightAnchor.constraint(equalTo: iconView.leftAnchor, constant: -22)
        ])
        self.nameLabel = nameLabel

        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .copySRegular
        descLabel.textColor = .mainGrey
        descLabel.numberOfLines = 0
        addSubview(descLabel)
        NSLayoutConstraint.activate([
            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            descLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            descLabel.rightAnchor.constraint(equalTo: iconView.leftAnchor, constant: -22)
        ])
        self.descLabel = descLabel

        let officersLabel = UILabel()
        officersLabel.translatesAutoresizingMaskIntoConstraints = false
        officersLabel.font = .copySRegular
        officersLabel.textColor = .mainGrey
        officersLabel.numberOfLines = 0
        addSubview(officersLabel)
        NSLayoutConstraint.activate([
            officersLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 16),
            officersLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            officersLabel.rightAnchor.constraint(equalTo: iconView.leftAnchor, constant: -22),
            bottomAnchor.constraint(equalTo: officersLabel.bottomAnchor, constant: 32)
        ])
        self.officersLabel = officersLabel
    }

    func configure(from pin: ScenePin) {
        let type = ScenePinType(rawValue: pin.type ?? "")
        if let type = type {
            iconView.isHidden = false
            iconView.image = type.image.scaledBy(1.5)
            iconView.backgroundColor = type.color
        } else {
            iconView.isHidden = true
        }

        if type == .other {
            nameLabel.text = pin.name
        } else {
            nameLabel.text = type?.description
        }
        descLabel.text = pin.desc
    }
}
