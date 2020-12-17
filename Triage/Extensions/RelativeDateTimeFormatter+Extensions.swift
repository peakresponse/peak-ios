//
//  RelativeDateTimeFormatter+Extensions.swift
//  Triage
//
//  Created by Francis Li on 3/16/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension RelativeDateTimeFormatter {
    static let defaultFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    static func localizedString(for date: Date, relativeTo: Date = Date()) -> String {
        return defaultFormatter.localizedString(for: date, relativeTo: relativeTo)
    }
}
