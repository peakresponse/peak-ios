//
//  FacilityTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 4/7/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class FacilityTableViewCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.cornerRadius = 5;
        containerView.addShadow(withOffset: CGSize(width: 1, height: 2), radius: 2, color: .black, opacity: 0.1)
        headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        headerView.layer.cornerRadius = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        headerView.backgroundColor = selected ? .natBlue : .natBlueLightened
        containerView.backgroundColor = selected ? .gray4 : .white
        nameLabel.textColor = selected ? .white : .gray2
        distanceLabel.textColor = selected ? .white : .natBlue
        addressLabel.textColor = selected ? .gray2 : .gray3
    }

    func configure(from facility: Facility) {
        nameLabel.text = facility.name
        addressLabel.text = facility.address
        distanceLabel.text = nil
        if facility.distance < Double.greatestFiniteMagnitude {
            distanceLabel.text = String(format: "%.1f mi", facility.distance.toMiles)
        }
    }

    func configure(from agency: Agency) {
        nameLabel.text = agency.stateNumber
        addressLabel.text = agency.name
        distanceLabel.text = nil
    }

    static func height(for text: String?) -> CGFloat {
        let font = UIFont(name: "NunitoSans-SemiBold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
        return 8 + 6 + font.lineHeight + 6 + font.lineHeight + 16 + 8
    }

    static func height(for agency: Agency) -> CGFloat {
        return FacilityTableViewCell.height(for: agency.name)
    }

    static func height(for facility: Facility) -> CGFloat {
        return FacilityTableViewCell.height(for: facility.address)
    }
}
