//
//  SNOMEDKeyboardSource.swift
//  Triage
//
//  Created by Francis Li on 12/17/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift
import SNOMEDKit

class SNOMEDKeyboardSource: KeyboardSource {
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

    func firstIndex(of value: String) -> Int? {
        guard let code = SCTRealm.open().object(ofType: SCTConcept.self, forPrimaryKey: value) else { return nil }
        if let filteredResults = filteredResults {
            return filteredResults.firstIndex(of: code)
        }
        return results?.firstIndex(of: code) ?? nil
    }

    func search(_ query: String?) {
        if let query = query?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            filteredResults = results?.filter("name CONTAINS[cd] %@", query, query)
        } else {
            filteredResults = nil
        }
    }

    func title(for value: String?) -> String? {
        guard let code = SCTRealm.open().object(ofType: SCTConcept.self, forPrimaryKey: value) else { return nil }
        return "\(code.id): \(code.name)"
    }

    func title(at index: Int) -> String? {
        if let filteredResults = filteredResults {
            return "\(filteredResults[index].id): \(filteredResults[index].name)"
        }
        return "\(results?[index].id ?? ""): \(results?[index].name ?? "")"
    }

    func value(at index: Int) -> String? {
        var value: String?
        if let filteredResults = filteredResults {
            value = filteredResults[index].id
        } else {
            value = results?[index].id
        }
        return value
    }
}
