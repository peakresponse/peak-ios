//
//  UIBarButtonItem+Extensions.swift
//  Triage
//
//  Created by Francis Li on 8/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit
import PRKit

extension UIBarButtonItem: Localizable {
    @IBInspectable public var l10nKey: String? {
        get { return nil }
        set { title = newValue?.localized }
    }
}
