//
//  ISO8601DateFormatter+Extensions.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import Foundation

extension ISO8601DateFormatter {
    static let defaultFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func date(from string: Any?) -> Date? {
        if let string = string as? String {
            return defaultFormatter.date(from: string)
        }
        return nil
    }

    static func string(from date: Date) -> String {
        return defaultFormatter.string(from: date)
    }
}
