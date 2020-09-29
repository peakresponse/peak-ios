//
//  TabBarController.swift
//  Triage
//
//  Created by Francis Li on 11/3/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, TabBarDelegate {
    weak var customTabBar: TabBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        // hide system tab bar
        tabBar.alpha = 0
        // set up custom tab bar, overlaying existing tab bar
        let customTabBar = TabBar()
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        customTabBar.tabBar = tabBar
        customTabBar.delegate = self
        customTabBar.items = viewControllers?.map({ $0.tabBarItem })
        customTabBar.selectedItem = customTabBar.items?.first
        view.addSubview(customTabBar)
        NSLayoutConstraint.activate([
            customTabBar.topAnchor.constraint(equalTo: tabBar.topAnchor),
            customTabBar.leftAnchor.constraint(equalTo: tabBar.leftAnchor),
            customTabBar.rightAnchor.constraint(equalTo: tabBar.rightAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor)
        ])
        self.customTabBar = customTabBar
    }

    // MARK: - TabBarDelegate

    func customTabBar(_ tabBar: TabBar, didSelectItem item: UITabBarItem) {
        if let index = tabBar.items?.firstIndex(of: item) {
            if let item = item as? TabBarItem, let identifier = item.segueIdentifier {
                performSegue(withIdentifier: identifier, sender: self)
            } else {
                selectedIndex = index
            }
        }
    }
}
