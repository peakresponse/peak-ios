//
//  TableViewHeaderView.swift
//  Triage
//
//  Created by Francis Li on 3/20/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class TableViewHeaderView: UITableViewHeaderFooterView {
    private let _textLabel = UILabel()
    override var textLabel: UILabel? {
        return _textLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundView = UIView()

        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .greyPeakBlue
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            view.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            view.heightAnchor.constraint(equalToConstant: 34)
        ])

        _textLabel.translatesAutoresizingMaskIntoConstraints = false
        _textLabel.font = .copySBold
        _textLabel.textColor = .white
        contentView.addSubview(_textLabel)
        NSLayoutConstraint.activate([
            _textLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            _textLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
