//
//  PortraitTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

@objc protocol PortraitTableViewCellCelegate: PriorityViewDelegate {
    @objc optional func portaitTableViewCellDidPressTransportButton(_ cell: PortraitTableViewCell)
}

class PortraitTableViewCell: PatientTableViewCell, PriorityViewDelegate {
    @IBOutlet weak var priorityView: UIView!
    @IBOutlet weak var prioritySelectorView: PriorityView!
    @IBOutlet weak var patientView: PatientView!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var transportButton: UIButton!
    
    weak var delegate: PortraitTableViewCellCelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        patientView.imageView.layer.borderWidth = 6
        patientView.imageView.layer.borderColor = UIColor.white.cgColor
        patientView.addShadow(withOffset: CGSize(width: 0, height: 4), radius: 4, color: .black, opacity: 0.25)
        editButton.setBackgroundImage(UIImage.resizableImage(withColor: .bottomBlueGray, cornerRadius: 3), for: .normal)
        transportButton.setBackgroundImage(UIImage.resizableImage(withColor: .bottomBlueGray, cornerRadius: 3), for: .normal)
        prioritySelectorView.isHidden = true
        prioritySelectorView.delegate = self
    }

    override func configure(from patient: Patient) {
        selectionStyle = .none
        patientView.configure(from: patient)
        priorityView.backgroundColor = PRIORITY_COLORS[patient.priority.value ?? 5]
        prioritySelectorView.isHidden = true
        prioritySelectorView.select(priority: patient.priority.value)
        contentView.backgroundColor = PRIORITY_COLORS_LIGHTENED[patient.priority.value ?? 5]
        priorityLabel.text = NSLocalizedString("Patient.priority.\(patient.priority.value ?? 5)", comment: "")
        priorityLabel.textColor = PRIORITY_LABEL_COLORS[patient.priority.value ?? 5]
        nameLabel.text = patient.fullName
        updatedLabel.text = patient.updatedAtRelativeString
    }

    @IBAction func editPressed(_ sender: Any) {
        prioritySelectorView.isHidden = !prioritySelectorView.isHidden
    }

    @IBAction func transportPressed(_ sender: Any) {
        delegate?.portaitTableViewCellDidPressTransportButton?(self)
    }
    
    // MARK: - PriorityViewDelegate

    func priorityView(_ view: PriorityView, didSelect priority: Int) {
        delegate?.priorityView?(view, didSelect: priority)
    }
    
    // MARK: - UITableViewCell

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        patientView.isEditing = editing
    }
}
