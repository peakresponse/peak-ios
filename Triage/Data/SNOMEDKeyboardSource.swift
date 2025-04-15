//
//  SNOMEDKeyboardSource.swift
//  Triage
//
//  Created by Francis Li on 12/17/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
internal import RealmSwift
internal import SNOMEDKit

@MainActor
class SNOMEDKeyboardSource: @preconcurrency KeyboardSource {
    var name: String {
        return "SNOMED"
    }
    var results: Results<SCTConcept>?
    var filteredResults: Results<SCTConcept>?

    init() {
        results = SCTRealm.open().objects(SCTConcept.self).sorted(by: [
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
        guard let code = SCTRealm.open().object(ofType: SCTConcept.self, forPrimaryKey: id) else { return nil }
        if let filteredResults = filteredResults {
            return filteredResults.firstIndex(of: code)
        }
        return results?.firstIndex(of: code)
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
        guard let code = SCTRealm.open().object(ofType: SCTConcept.self, forPrimaryKey: id) else { return nil }
        return "\(code.id): \(code.name)"
    }

    func title(at index: Int) -> String? {
        if let filteredResults = filteredResults {
            return "\(filteredResults[index].id): \(filteredResults[index].name)"
        }
        return "\(results?[index].id ?? ""): \(results?[index].name ?? "")"
    }

    func value(at index: Int) -> NSObject? {
        if let filteredResults = filteredResults {
            return NemsisValue(text: filteredResults[index].id)
        }
        return NemsisValue(text: results?[index].id)
    }
}
