//
//  UITabBar+Extensions.swift
//  Triage
//
//  Created by Francis Li on 3/10/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

extension UITabBar {
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        if let safeAreaInsets = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.safeAreaInsets {
            if safeAreaInsets.bottom > 0 {
                sizeThatFits.height = 100
                if let items = items {
                    for item in items {
                        item.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
                    }
                }
            }
        }
        return sizeThatFits
    }
}
