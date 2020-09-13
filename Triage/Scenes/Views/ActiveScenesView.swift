//
//  ActiveScenesView.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

@IBDesignable
class ActiveSceneView: UIView {
    var id: String?
    
    var isMaximized = false
    var bottomHeaderViewConstraint: NSLayoutConstraint!
    
    weak var headerView: UIView!
    weak var iconView: UIImageView!
    weak var nameLabel: UILabel!
    weak var descLabel: UILabel!
    
    weak var bodyView: UIView!
    weak var mapView: UIView!
    weak var dateLabel: UILabel!
    weak var patientsCountLabel: UILabel!
    weak var patientsLabel: UILabel!
    weak var transportedCountLabel: UILabel!
    weak var transportedLabel: UILabel!
    weak var respondersCountLabel: UILabel!
    weak var respondersLabel: UILabel!
    weak var joinButton: FormButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        let headerView = UIView()
        headerView.backgroundColor = .orangeAccent
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leftAnchor.constraint(equalTo: leftAnchor),
            headerView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        self.headerView = headerView

        let iconView = UIImageView(image: UIImage(named: "Maximize"), highlightedImage: UIImage(named: "Minimize"))
        iconView.tintColor = .white
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        headerView.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -20),
            iconView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10)
        ])
        self.iconView = iconView
        
        let nameLabel = UILabel()
        nameLabel.font = .copyMBold
        nameLabel.numberOfLines = 1
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            nameLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 20),
            nameLabel.rightAnchor.constraint(equalTo: iconView.leftAnchor, constant: -22)
        ])
        self.nameLabel = nameLabel

        let descLabel = UILabel()
        descLabel.font = .copyXSBold
        descLabel.numberOfLines = 1
        descLabel.textColor = .white
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(descLabel)
        NSLayoutConstraint.activate([
            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            descLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            descLabel.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -20),
            headerView.bottomAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 10)
        ])
        self.descLabel = descLabel

        bottomHeaderViewConstraint = bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        bottomHeaderViewConstraint.isActive = true
    }

    func configure(from scene: Scene) {
        id = scene.id
        nameLabel.text = (scene.name ?? "").isEmpty ? " " : scene.name
        descLabel.text = (scene.desc ?? "").isEmpty ? " " : scene.desc
    }
}

class ActiveScenesView: UIView {
    weak var stackView: UIStackView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .white

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 2
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 2),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -2),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            topAnchor.constraint(equalTo: stackView.topAnchor, constant: -2)
        ])
        self.stackView = stackView
    }
    
    func configure(from results: Results<Scene>) {
        var index = 0
        for scene in results {
            var found = false
            for view in stackView.arrangedSubviews {
                if let view = view as? ActiveSceneView, view.id == scene.id {
                    view.configure(from: scene)
                    found = true
                    break
                }
            }
            if !found {
                let view = ActiveSceneView()
                view.configure(from: scene)
                stackView.insertArrangedSubview(view, at: index)
                index += 1
            }
        }
    }
}
