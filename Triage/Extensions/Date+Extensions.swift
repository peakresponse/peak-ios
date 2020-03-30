//
//  Date+Extensions.swift
//  Triage
//
//  Created by Francis Li on 3/16/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation

extension Date {
    func asRelativeString() -> String {
        return RelativeDateTimeFormatter.localizedString(for: self)
    }

    func asLocalizedTime() -> String {
        return DateFormatter.localizedString(from: self, dateStyle: .none, timeStyle: .short)
    }
}
