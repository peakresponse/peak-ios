//
//  Base.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import RealmSwift

class Base: Object {
    struct Keys {
        static let id = "id"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }

    @objc dynamic var id = UUID().uuidString.lowercased()
    @objc dynamic var createdAt: Date?
    @objc dynamic var updatedAt: Date?
    var updatedAtRelativeString: String {
        return updatedAt?.asRelativeString() ?? "Unknown".localized
    }

    override required init() {
        super.init()
    }

    convenience init(clone: Any) {
        self.init(value: clone)
        id = UUID().uuidString.lowercased()
    }

    override public class func primaryKey() -> String? {
        return "id"
    }

    func update(from data: [String: Any]) {
        if let value = data[Keys.id] as? String {
            id = value
        }
        if data.index(forKey: Keys.createdAt) != nil {
            createdAt = ISO8601DateFormatter.date(from: data[Keys.createdAt]) ?? Date()
        }
        if data.index(forKey: Keys.updatedAt) != nil {
            updatedAt = ISO8601DateFormatter.date(from: data[Keys.updatedAt]) ?? Date()
        }
    }

    func asJSON() -> [String: Any] {
        var data: [String: Any] = [:]
        data[Keys.id] = id
        return data
    }

    static func instantiate(from data: [String: Any]) -> Base {
        let obj = self.init()
        obj.update(from: data)
        return obj
    }
}
