//
//  UIButton+Extensions.swift
//  Triage
//
//  Created by Francis Li on 8/21/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

extension UIButton: Localizable {
    @IBInspectable var l10nKey: String? {
        get { return nil }
        set { setTitle(newValue?.localized, for: .normal) }
    }

    @IBInspectable var customFont: String? {
        get { return nil }
        set { titleLabel?.font = UIFont.value(forKey: newValue ?? "") as? UIFont }
    }
}
