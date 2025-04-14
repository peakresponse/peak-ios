//
//  AgencyKeyboardSource.swift
//  Triage
//
//  Created by Francis Li on 2/26/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
internal import RealmSwift

class AgencyKeyboardSource: KeyboardSource {
    var name: String {
        return "Agency".localized
    }
    var results: Results<RegionAgency>?
    var filteredResults: Results<RegionAgency>?

    init() {
        results = AppRealm.open().objects(RegionAgency.self).sorted(byKeyPath: "position", ascending: true)
    }

    func count() -> Int {
        if let filteredResults = filteredResults {
            return filteredResults.count
        }
        return results?.count ?? 0
    }

    func firstIndex(of value: NSObject) -> Int? {
        guard let id = (value as? Agency)?.id else { return nil }
        if let filteredResults = filteredResults {
            for (i, ra) in filteredResults.enumerated() {
                if ra.agency?.id == id {
                    return i
                }
            }
            return nil
        }
        if let results = results {
            for (i, ra) in results.enumerated() {
                if ra.agency?.id == id {
                    return i
                }
            }
        }
        return nil
    }

    func search(_ query: String?, callback: ((Bool) -> Void)?) {
        if let query = query?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            filteredResults = results?.filter("agency.name CONTAINS[cd] %@", query)
        } else {
            filteredResults = nil
        }
        callback?(false)
    }

    func title(for value: NSObject?) -> String? {
        guard let agency = value as? Agency else { return nil }
        return agency.displayName ?? ""
    }

    func title(at index: Int) -> String? {
        var agency: Agency?
        if let filteredResults = filteredResults {
            agency = filteredResults[index].agency
        } else {
            agency = results?[index].agency
        }
        return agency?.displayName ?? ""
    }

    func value(at index: Int) -> NSObject? {
        if let filteredResults = filteredResults {
            return filteredResults[index].agency
        }
        return results?[index].agency
    }
}
