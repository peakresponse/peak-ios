//
//  String+Extensions.swift
//  Triage
//
//  Created by Francis Li on 8/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, bundle: Bundle(for: AppDelegate.self), comment: "")
    }
}
