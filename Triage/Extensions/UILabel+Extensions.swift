//
//  UILabel+Extensions.swift
//  Triage
//
//  Created by Francis Li on 8/18/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

extension UILabel: Localizable {
    @IBInspectable var l10nKey: String? {
        get { return nil }
        set { text = newValue?.localized }
    }

    @IBInspectable var customFont: String? {
        get { return nil }
        set { font = UIFont.value(forKey: newValue ?? "") as? UIFont }
    }
}
