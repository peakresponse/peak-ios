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

    override var tabBarItem: UITabBarItem! {
        get {
            if let tabBarItem = viewControllers.first?.tabBarItem {
                return tabBarItem
            }
            return super.tabBarItem
        }
        set { super.tabBarItem = newValue }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iconView = UIImageView(image: UIImage(named: "Icon"))
        if let iconView = iconView {
            iconView.translatesAutoresizingMaskIntoConstraints = false
            navigationBar.addSubview(iconView)
            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: 36),
                iconView.heightAnchor.constraint(equalToConstant: 30),
                iconView.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor)
            ])
        }
    }
}
