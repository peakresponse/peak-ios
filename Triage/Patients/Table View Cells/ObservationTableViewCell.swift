//
//  ObservationTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 3/29/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@objc protocol ObservationTableViewCellDelegate {
    @objc optional func observationTableViewCell(_ cell: ObservationTableViewCell, didChange text: String)
    @objc optional func observationTableViewCellDidReturn(_ cell: ObservationTableViewCell)
}

class ObservationTableViewCell: PatientTableViewCell, PatientTableViewCellBackground, UITextViewDelegate {        
    static func heightForText(_ text: String, width: CGFloat) -> CGFloat {
        return ObservationView.heightForText(text, width: width - 50 /* left and right margins */) + 10 /* top and bottom margins*/
    }

    @IBOutlet weak var customBackgroundView: UIView!
    @IBOutlet weak var observationView: ObservationView!

    weak var delegate: ObservationTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        observationView.textView.delegate = self
    }
    
    override func configure(from patient: Patient) {
        observationView.configure(from: patient)
    }
    
    override func becomeFirstResponder() -> Bool {
        return observationView.textView.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return observationView.textView.resignFirstResponder()
    }
    
    // MARK: - UITableViewCell
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        observationView.textView.isUserInteractionEnabled = editing
        observationView.textView.isEditable = editing
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        delegate?.observationTableViewCell?(self, didChange: textView.text)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            delegate?.observationTableViewCellDidReturn?(self)
            return false
        }
        return true
    }
}
