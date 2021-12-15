//
//  NemsisNegativeKeyboard.swift
//  Triage
//
//  Created by Francis Li on 12/13/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation
import PRKit

class NemsisNegativeKeyboard: PickerKeyboard, KeyboardSource {
    var negatives: [NemsisNegative]

    init(negatives: [NemsisNegative]) {
        self.negatives = negatives
        super.init()
        source = self
    }

    required init?(coder: NSCoder) {
        self.negatives = []
        super.init(coder: coder)
        source = self
    }

    func count() -> Int {
        return negatives.count + 1
    }

    func firstIndex(of value: String) -> Int? {
        if let index = negatives.firstIndex(where: { $0.rawValue == value }) {
            return index + 1
        }
        return nil
    }

    func search(_ query: String?) {

    }

    func title(for value: String?) -> String? {
        if value == nil {
            return ""
        }
        return negatives.first(where: {$0.rawValue == value})?.description
    }

    func title(at index: Int) -> String? {
        if index == 0 {
            return ""
        }
        return negatives[index - 1].description
    }

    func value(at index: Int) -> String? {
        if index == 0 {
            return nil
        }
        return negatives[index - 1].rawValue
    }
}
