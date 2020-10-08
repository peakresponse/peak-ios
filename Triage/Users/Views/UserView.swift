//
//  UserView.swift
//  Triage
//
//  Created by Francis Li on 10/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class UserView: UIView {
    weak var imageView: RoundImageView!
    weak var nameStackView: UIStackView!
    weak var nameLabel: UILabel!
    weak var positionLabel: UILabel!
    weak var agencyLabel: UILabel!
    weak var statusStackView: UIStackView!
    weak var statusLabel: UILabel!
    weak var dateLabel: UILabel!
    weak var roleImageView: RoundImageView!

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
        addShadow(withOffset: CGSize(width: 2, height: 2), radius: 4, color: .black, opacity: 0.1)

        let imageView = RoundImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .greyPeakBlue
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            imageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            imageView.widthAnchor.constraint(equalToConstant: 48),
            imageView.heightAnchor.constraint(equalToConstant: 48),
            bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10)
        ])
        self.imageView = imageView

        let nameStackView = UIStackView()
        nameStackView.translatesAutoresizingMaskIntoConstraints = false
        nameStackView.axis = .vertical
        addSubview(nameStackView)
        NSLayoutConstraint.activate([
            nameStackView.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: 10),
            nameStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
            nameStackView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
        self.nameStackView = nameStackView

        let nameLabel = UILabel()
        nameLabel.font = .copySBold
        nameLabel.textColor = .mainGrey
        nameStackView.addArrangedSubview(nameLabel)
        self.nameLabel = nameLabel

        let positionLabel = UILabel()
        positionLabel.font = .copyXSRegular
        positionLabel.textColor = .mainGrey
        nameStackView.addArrangedSubview(positionLabel)
        self.positionLabel = positionLabel

        let agencyLabel = UILabel()
        agencyLabel.translatesAutoresizingMaskIntoConstraints = false
        agencyLabel.font = .copyXSRegular
        agencyLabel.textColor = .mainGrey
        addSubview(agencyLabel)
        NSLayoutConstraint.activate([
            agencyLabel.leftAnchor.constraint(equalTo: nameStackView.leftAnchor),
            agencyLabel.topAnchor.constraint(equalTo: nameStackView.bottomAnchor)
        ])
        self.agencyLabel = agencyLabel

        let statusStackView = UIStackView()
        statusStackView.translatesAutoresizingMaskIntoConstraints = false
        statusStackView.axis = .horizontal
        addSubview(statusStackView)
        NSLayoutConstraint.activate([
            statusStackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            statusStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8)
        ])
        self.statusStackView = statusStackView

        let statusLabel = UILabel()
        statusLabel.font = .copySBold
        statusLabel.textColor = .greyPeakBlue
        statusStackView.addArrangedSubview(statusLabel)
        self.statusLabel = statusLabel

        let dateLabel = UILabel()
        dateLabel.font = .copySRegular
        dateLabel.textColor = .greyPeakBlue
        statusStackView.addArrangedSubview(dateLabel)
        self.dateLabel = dateLabel

        let roleImageView = RoundImageView()
        roleImageView.translatesAutoresizingMaskIntoConstraints = false
        roleImageView.imageView.contentMode = .center
        addSubview(roleImageView)
        NSLayoutConstraint.activate([
            roleImageView.widthAnchor.constraint(equalToConstant: 32),
            roleImageView.heightAnchor.constraint(equalToConstant: 32),
            roleImageView.rightAnchor.constraint(equalTo: rightAnchor, constant: -7),
            roleImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
        self.roleImageView = roleImageView
    }

    func configure(from responder: Responder, isMGS: Bool = false) {
        if let imageURL = responder.user?.iconUrl {
            imageView.imageURL = imageURL
        } else {
            imageView.image = UIImage(named: "User")
        }
        nameLabel.text = responder.user?.fullName
        positionLabel.text = responder.user?.position
        agencyLabel.text = responder.agency?.name

        if isMGS {
            roleImageView.isHidden = false
            roleImageView.backgroundColor = .peakBlue
            roleImageView.image = UIImage(named: "Star")
        } else if let role = ResponderRole(rawValue: responder.role ?? "") {
            roleImageView.isHidden = false
            roleImageView.backgroundColor = role.color
            roleImageView.image = role.image
        } else {
            roleImageView.isHidden = true
        }
    }
}
