//
//  StateKeyboardSource.swift
//  Triage
//
//  Created by Francis Li on 10/24/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation
import PRKit
internal import RealmSwift

class StateKeyboardSource: KeyboardSource {
    var name: String {
        return "State"
    }
    var results: Results<State>?
    var filteredResults: Results<State>?

    init() {
        results = AppRealm.open().objects(State.self).sorted(by: [
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
        guard let value = value as? String else { return nil }
        guard let state = AppRealm.open().object(ofType: State.self, forPrimaryKey: value) else { return nil }
        if let filteredResults = filteredResults {
            return filteredResults.firstIndex(of: state)
        }
        return results?.firstIndex(of: state) ?? nil
    }

    func search(_ query: String?, callback: ((Bool) -> Void)? = nil) {
        if let query = query?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            filteredResults = results?.filter("name CONTAINS[cd] %@", query, query)
            AppRealm.getStates(search: query) { (error) in
                DispatchQueue.main.async {
                    callback?(error == nil)
                }
            }
        } else {
            filteredResults = nil
            callback?(false)
        }
    }

    func title(for value: NSObject?) -> String? {
        guard let value = value as? String else { return nil }
        guard let state = AppRealm.open().object(ofType: State.self, forPrimaryKey: value) else { return nil }
        return state.name ?? ""
    }

    func title(at index: Int) -> String? {
        if let filteredResults = filteredResults {
            return filteredResults[index].name ?? ""
        }
        return results?[index].name ?? ""
    }

    func value(at index: Int) -> NSObject? {
        var value: String?
        if let filteredResults = filteredResults {
            value = filteredResults[index].id
        } else {
            value = results?[index].id
        }
        return value as NSObject?
    }
}
