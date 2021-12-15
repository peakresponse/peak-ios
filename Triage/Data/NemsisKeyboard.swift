//
//  NemsisKeyboard.swift
//  Triage
//
//  Created by Francis Li on 12/7/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation
import PRKit

class NemsisKeyboard: SearchKeyboard {
    var field: String?

    init(field: String, isMultiSelect: Bool) {
        super.init(source: ICD10CMKeyboardSource(), isMultiSelect: isMultiSelect)
        self.field = field
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func searchPressed() {
        let vc = NemsisKeyboardViewController()
        vc.field = field
        vc.source = source
        vc.values = values
        vc.isMultiSelect = isMultiSelect
        vc.delegate = self
        delegate?.formInputView(self, wantsToPresent: vc)
    }

    override func text(for value: AnyObject?) -> String? {
        if let value = value as? String, let field = field {
            let realm = AppRealm.open()
            if let list = realm.objects(CodeList.self).filter("%@ IN fields", field).first,
               let item = realm.objects(CodeListItem.self).filter("list=%@ AND code=%@", list, value).first {
                var text = item.name
                if let sectionName = item.section?.name {
                    text = "\(sectionName): \(text ?? "")"
                }
                return text
            }
        }
        return super.text(for: value)
    }
}
