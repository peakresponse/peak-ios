//
//  ActiveScenesView.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

@objc protocol ActiveScenesViewDelegate {
    @objc optional func activeScenesView(_ view: ActiveScenesView, didJoinScene scene: Scene)
    @objc optional func activeScenesView(_ view: ActiveScenesView, didViewScene scene: Scene)
}

@IBDesignable
class ActiveScenesView: UIView, ActiveSceneViewDelegate {
    weak var stackView: UIStackView!
    weak var delegate: ActiveScenesViewDelegate?

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
        var views: [ActiveSceneView] = []
        for scene in results {
            var found = false
            for view in stackView.arrangedSubviews {
                if let view = view as? ActiveSceneView, view.scene.id == scene.id {
                    view.configure(from: scene)
                    views.append(view)
                    found = true
                    break
                }
            }
            if !found {
                let view = ActiveSceneView()
                view.delegate = self
                view.configure(from: scene)
                views.append(view)
            }
        }
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        var isMaximized = false
        for view in views {
            isMaximized = isMaximized || view.isMaximized
            stackView.addArrangedSubview(view)
        }
        if !isMaximized && views.count > 0 {
            views[0].isMaximized = true
        }
    }

    // MARK: - ActiveSceneViewDelegate

    func activeSceneView(_ view: ActiveSceneView, didJoinScene scene: Scene) {
        delegate?.activeScenesView?(self, didJoinScene: scene)
    }

    func activeSceneView(_ view: ActiveSceneView, didViewScene scene: Scene) {
        delegate?.activeScenesView?(self, didViewScene: scene)
    }

    func activeSceneViewDidMaximize(_ view: ActiveSceneView) {
        for subview in stackView.arrangedSubviews where subview != view {
            if let subview = subview as? ActiveSceneView {
                subview.isMaximized = false
            }
        }
    }
}
