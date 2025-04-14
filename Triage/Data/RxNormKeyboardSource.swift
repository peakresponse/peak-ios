//
//  RxNormKeyboardSource.swift
//  Triage
//
//  Created by Francis Li on 12/14/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
internal import RealmSwift
internal import RxNormKit

@MainActor
class RxNormKeyboardSource: @preconcurrency KeyboardSource {
    var name: String {
        return "RxNorm"
    }
    var results: Results<RxNConcept>?
    var filteredResults: Results<RxNConcept>?
    var includeSystem = false

    init(includeSystem: Bool = false) {
        self.includeSystem = includeSystem
        results = RxNRealm.open().objects(RxNConcept.self).sorted(by: [
            SortDescriptor(keyPath: "tty", ascending: true),
            SortDescriptor(keyPath: "name", ascending: true)
        ])
    }

    func count() -> Int {
        if let filteredResults = filteredResults {
            return filteredResults.count
        }
        return results?.count ?? 0
    }

    func firstIndex(of value: NSObject) -> Int? {
        guard let value = value as? NemsisValue, !value.isNil, let id = value.text else { return nil }
        guard let code = RxNRealm.open().object(ofType: RxNConcept.self, forPrimaryKey: Int(id)) else { return nil }
        if let filteredResults = filteredResults {
            return filteredResults.firstIndex(of: code)
        }
        return results?.firstIndex(of: code) ?? nil
    }

    func search(_ query: String?, callback: ((Bool) -> Void)? = nil) {
        if let query = query?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            filteredResults = results?.filter("name CONTAINS[cd] %@", query, query)
        } else {
            filteredResults = nil
        }
        callback?(false)
    }

    func title(for value: NSObject?) -> String? {
        guard let value = value as? NemsisValue, !value.isNil, let id = value.text else { return nil }
        guard let code = RxNRealm.open().object(ofType: RxNConcept.self, forPrimaryKey: Int(id)) else { return nil }
        return "\(code.name.capitalized)"
    }

    func title(at index: Int) -> String? {
        if let filteredResults = filteredResults {
            return "\(filteredResults[index].name.capitalized)"
        }
        return "\(results?[index].name.capitalized ?? "")"
    }

    func value(at index: Int) -> NSObject? {
        var value: Int?
        if let filteredResults = filteredResults {
            value = filteredResults[index].rxcui
        } else {
            value = results?[index].rxcui
        }
        if let value = value {
            let nemsisValue = NemsisValue(text: String(value))
            nemsisValue.attributes = [:]
            nemsisValue.attributes?["CodeType"] = MedicationCodeType.rxNorm.rawValue
            return nemsisValue
        }
        return nil
    }
}
