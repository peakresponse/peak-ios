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
    @objc optional func observationTableViewCell(_ cell: ObservationTableViewCell, didThrowError error: Error)
    @objc optional func observationTableViewCellDidReturn(_ cell: ObservationTableViewCell)
}

class ObservationTableViewCell: PatientTableViewCell, ObservationViewDelegate, UITextViewDelegate {
    static func heightForText(_ text: String, width: CGFloat) -> CGFloat {
        return ObservationView.heightForText(text, width: width - 44 /* left and right margins */) + 10 /* top and bottom margins*/
    }

    override var inputAccessoryView: UIView? {
        get { return observationView.textView.inputAccessoryView }
        set { observationView.textView.inputAccessoryView = newValue }
    }
    
    let observationView = ObservationView()

    weak var delegate: ObservationTableViewCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundView = UIView()
        backgroundView?.backgroundColor = .bgBackground
        contentView.backgroundColor = .clear

        observationView.translatesAutoresizingMaskIntoConstraints = false
        observationView.delegate = self
        observationView.textView.delegate = self
        contentView.addSubview(observationView)
        NSLayoutConstraint.activate([
            observationView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            observationView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            observationView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -22),
            contentView.bottomAnchor.constraint(equalTo: observationView.bottomAnchor, constant: 5),
        ])
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

    // MARK: - ObservationViewDelegate

    func observationView(_ observationView: ObservationView, didThrowError error: Error) {
        delegate?.observationTableViewCell?(self, didThrowError: error)
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
