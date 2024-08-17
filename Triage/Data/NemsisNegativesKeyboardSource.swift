//
//  NemsisNegativesKeyboardSource.swift
//  Triage
//
//  Created by Francis Li on 8/17/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit

class NemsisNegativesKeyboardSource: KeyboardSource {
    var negatives: [NemsisNegative]

    init(negatives: [NemsisNegative]) {
        self.negatives = negatives
    }

    // MARK: - KeyboardSource

    var name: String {
        return "NemsisNegativesKeyboard.title".localized
    }

    func count() -> Int {
        return negatives.count
    }

    func firstIndex(of value: NSObject) -> Int? {
        guard let value = value as? NemsisValue, let negativeValue = value.NegativeValue else { return nil }
        return negatives.firstIndex(of: negativeValue)
    }

    func search(_ query: String?, callback: ((Bool) -> Void)? = nil) {
        callback?(false)
    }

    func title(for value: NSObject?) -> String? {
        guard let value = value as? NemsisValue else { return nil }
        return value.NegativeValue?.description
    }

    func title(at index: Int) -> String? {
        return negatives[index].description
    }

    func value(at index: Int) -> NSObject? {
        return NemsisValue(negativeValue: negatives[index].rawValue)
    }
}
