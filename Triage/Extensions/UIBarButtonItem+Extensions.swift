//
//  UIBarButtonItem+Extensions.swift
//  Triage
//
//  Created by Francis Li on 8/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

extension UIBarButtonItem: Localizable {
    @IBInspectable var l10nKey: String? {
        get { return nil }
        set { title = newValue?.localized }
    }
}
