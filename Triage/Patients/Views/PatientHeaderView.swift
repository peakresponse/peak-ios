//
//  PatientHeaderView.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class PatientHeaderView: UIView {
    weak var portraitView: PortraitView!
    weak var stackView: UIStackView!
    weak var tagLabel: UILabel!
    weak var updatedLabel: UILabel!

    var isEditing: Bool {
        get { return portraitView.isEditing }
        set { portraitView.isEditing = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .bgBackground

        let portraitView = PortraitView()
        portraitView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(portraitView)
        NSLayoutConstraint.activate([
            portraitView.widthAnchor.constraint(equalToConstant: 70),
            portraitView.heightAnchor.constraint(equalToConstant: 70),
            portraitView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            portraitView.rightAnchor.constraint(equalTo: rightAnchor, constant: -22),
            bottomAnchor.constraint(equalTo: portraitView.bottomAnchor, constant: 15)
        ])
        self.portraitView = portraitView

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: portraitView.centerYAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            stackView.rightAnchor.constraint(equalTo: portraitView.leftAnchor, constant: -22)
        ])
        self.stackView = stackView

        let tagLabel = UILabel()
        tagLabel.font = .copyLBold
        tagLabel.textColor = .mainGrey
        stackView.addArrangedSubview(tagLabel)
        self.tagLabel = tagLabel

        let updatedLabel = UILabel()
        updatedLabel.font = .copySRegular
        updatedLabel.textColor = .lowPriorityGrey
        stackView.addArrangedSubview(updatedLabel)
        self.updatedLabel = updatedLabel
    }

    func configure(from patient: Patient) {
        portraitView.configure(from: patient)

        tagLabel.text = String(format: "Patient.pin".localized, patient.pin ?? "")
        let format = "Patient.updatedAt".localized
        let range = format.startIndex..<(format.firstIndex(of: "%") ?? format.endIndex)
        let attributedText = NSMutableAttributedString(string: String(format: format, patient.updatedAtRelativeString))
        attributedText.addAttribute(.font,
                                    value: UIFont.copySBold,
                                    range: NSRange(range, in: format))
        updatedLabel.attributedText = attributedText
    }
}
