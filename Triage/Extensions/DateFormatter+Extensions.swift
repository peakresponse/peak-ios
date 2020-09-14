//
//  DateFormatter+Extensions.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation

extension DateFormatter {
    static let timeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma - MMM d, y"
        return formatter
    }()
}
