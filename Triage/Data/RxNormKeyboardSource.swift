//
//  RxNormKeyboardSource.swift
//  Triage
//
//  Created by Francis Li on 12/14/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift
import RxNormKit

class RxNormKeyboardSource: KeyboardSource {
    var name: String {
        return "RxNorm"
    }
    var results: Results<RxNConcept>?
    var filteredResults: Results<RxNConcept>?

    init() {
        results = RxNRealm.open().objects(RxNConcept.self).sorted(by: [
            SortDescriptor(keyPath: "rxcui", ascending: true),
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
        guard let code = RxNRealm.open().object(ofType: RxNConcept.self, forPrimaryKey: value) else { return nil }
        if let filteredResults = filteredResults {
            return filteredResults.firstIndex(of: code)
        }
        return results?.firstIndex(of: code) ?? nil
    }

    func search(_ query: String?) {
        if let query = query, !query.isEmpty {
            filteredResults = results?.filter("name CONTAINS[cd] %@", query, query)
        } else {
            filteredResults = nil
        }
    }

    func title(for value: String?) -> String? {
        guard let code = RxNRealm.open().object(ofType: RxNConcept.self, forPrimaryKey: Int(value ?? "")) else { return nil }
        return "\(code.rxcui): \(code.name)"
    }

    func title(at index: Int) -> String? {
        if let filteredResults = filteredResults {
            return "\(filteredResults[index].rxcui): \(filteredResults[index].name)"
        }
        return "\(results?[index].rxcui ?? 0): \(results?[index].name ?? "")"
    }

    func value(at index: Int) -> String? {
        var value: Int?
        if let filteredResults = filteredResults {
            value = filteredResults[index].rxcui
        } else {
            value = results?[index].rxcui
        }
        if let value = value {
            return String(value)
        }
        return nil
    }
}
