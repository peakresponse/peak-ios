//
//  ICD10CMKeyboardSource.swift
//  Triage
//
//  Created by Francis Li on 12/3/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import ICD10Kit
import PRKit
import RealmSwift

class ICD10CMKeyboardSource: KeyboardSource {
    var results: Results<CMCode>?
    var filteredResults: Results<CMCode>?

    init() {
        results = CMRealm.open().objects(CMCode.self).sorted(byKeyPath: "name", ascending: true)
    }

    func count() -> Int {
        if let filteredResults = filteredResults {
            return filteredResults.count
        }
        return results?.count ?? 0
    }

    func firstIndex(of value: String) -> Int? {
        guard let code = CMRealm.open().object(ofType: CMCode.self, forPrimaryKey: value) else { return nil }
        if let filteredResults = filteredResults {
            return filteredResults.firstIndex(of: code)
        }
        return results?.firstIndex(of: code) ?? nil
    }

    func search(_ query: String?) {
        if let query = query, !query.isEmpty {
            filteredResults = results?.filter("(name CONTAINS[cd] %@) OR (desc CONTAINS[cd] %@)", query, query)
        } else {
            filteredResults = nil
        }
    }

    func title(for value: String?) -> String? {
        guard let code = CMRealm.open().object(ofType: CMCode.self, forPrimaryKey: value) else { return nil }
        return "\(code.name ?? ""): \(code.desc ?? "")"
    }

    func title(at index: Int) -> String? {
        if let filteredResults = filteredResults {
            return "\(filteredResults[index].name ?? ""): \(filteredResults[index].desc ?? "")"
        }
        return "\(results?[index].name ?? ""): \(results?[index].desc ?? "")"
    }

    func value(at index: Int) -> String? {
        if let filteredResults = filteredResults {
            return filteredResults[index].name
        }
        return results?[index].name
    }
}
