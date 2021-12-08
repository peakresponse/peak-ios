//
//  ICD10CMKeyboard.swift
//  Triage
//
//  Created by Francis Li on 12/7/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation
import PRKit

class ICD10CMKeyboard: SearchKeyboard {
    var field: String?

    init(field: String, isMultiSelect: Bool) {
        super.init(source: ICD10CMKeyboardSource(), isMultiSelect: isMultiSelect)
        self.field = field
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func searchPressed() {
        let vc = ICD10CMViewController()
        vc.field = field
        vc.source = source
        vc.values = values
        vc.isMultiSelect = isMultiSelect
        vc.delegate = self
        delegate?.formInputView(self, wantsToPresent: vc)
    }
}
