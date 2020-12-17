//
//  UIActivityIndicatorView+Extensions.swift
//  Triage
//
//  Created by Francis Li on 12/14/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

extension UIActivityIndicatorView {
    static func withMediumStyle() -> UIActivityIndicatorView {
        var style: UIActivityIndicatorView.Style = .gray
        if #available(iOS 13.0, *) {
            style = .medium
        }
        return UIActivityIndicatorView(style: style)
    }

    static func withLargeStyle() -> UIActivityIndicatorView {
        var style: UIActivityIndicatorView.Style = .gray
        if #available(iOS 13.0, *) {
            style = .large
        }
        return UIActivityIndicatorView(style: style)
    }
}
