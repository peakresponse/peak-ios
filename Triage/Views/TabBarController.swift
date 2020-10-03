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

        // set up custom tab bar, overlaying existing tab bar
        let customTabBar = TabBar(frame: tabBar.bounds)
        customTabBar.tabBar = tabBar
        customTabBar.delegate = self
        customTabBar.items = viewControllers?.map({ $0.tabBarItem })
        customTabBar.selectedItem = customTabBar.items?.first
        tabBar.addSubview(customTabBar)
        self.customTabBar = customTabBar
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.bringSubviewToFront(customTabBar)
        customTabBar.frame = tabBar.bounds
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
