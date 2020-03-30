//
//  TextViewTableViewCell.swift
//  Triage
//
//  Created by Francis Li on 11/3/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

@objc protocol TextViewTableViewCellDelegate {
    @objc optional func textViewTableViewCell(_ cell: TextViewTableViewCell, didChange text: String)
    @objc optional func textViewTableViewCellDidReturn(_ cell: TextViewTableViewCell)
}

class TextViewTableViewCell: PatientTableViewCell, PatientTableViewCellBackground, UITextViewDelegate {
    @IBOutlet weak var customBackgroundView: UIView!
    @IBOutlet weak var textView: UITextView!

    weak var delegate: TextViewTableViewCellDelegate?
    var attribute: String!

    override func awakeFromNib() {
        super.awakeFromNib()
        textView.contentInset = .zero
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
    }

    override func configure(from patient: Patient) {
        if let value = patient.value(forKey: attribute),
            let font = textView.font,
            let textColor = textView.textColor {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            textView.attributedText = NSAttributedString(string: String(describing: value), attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: textColor
            ])
        } else {
            textView.text = nil
        }
        textView.returnKeyType = .next
    }

    static func heightForText(_ text: String, width: CGFloat) -> CGFloat {
        let font = UIFont(name: "NunitoSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        let text = text as NSString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        let rect = text.boundingRect(with: CGSize(width: width - 80, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [
            .font: font,
            .paragraphStyle: paragraphStyle
        ], context: nil)
        return round(rect.height) + 26
    }

    override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }
    
    // MARK: - UITableViewCell
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        textView.isUserInteractionEnabled = editing
        textView.isEditable = editing
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        delegate?.textViewTableViewCell?(self, didChange: textView.text)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            delegate?.textViewTableViewCellDidReturn?(self)
            return false
        }
        return true
    }
}
