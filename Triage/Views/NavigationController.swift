//
//  NavigationController.swift
//  Triage
//
//  Created by Francis Li on 3/11/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    var iconView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.backgroundColor = UIColor.clear
        
        iconView = UIImageView(image: UIImage(named: "Icon"))
        if let iconView = iconView {
            iconView.addShadow(withOffset: CGSize(width: 0, height: 4), radius: 4, color: UIColor.black, opacity: 0.1)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            navigationBar.addSubview(iconView)
            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: 50),
                iconView.heightAnchor.constraint(equalToConstant: 50),
                iconView.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor)
            ])
        }
    }
}
