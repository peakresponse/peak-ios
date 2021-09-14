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

class BaseVersioned: Base {
    struct Keys {
        static let canonicalId = "canonicalId"
        static let currentId = "currentId"
        static let parentId = "parentId"
        static let secondParentId = "secondParentId"
    }

    @objc dynamic var canonicalId: String?
    @objc dynamic var currentId: String?
    @objc dynamic var parentId: String?
    @objc dynamic var secondParentId: String?

    func new() {
        canonicalId = UUID().uuidString.lowercased()
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        canonicalId = data[Keys.canonicalId] as? String
        currentId = data[Keys.currentId] as? String
        parentId = data[Keys.parentId] as? String
        secondParentId = data[Keys.secondParentId] as? String
    }

    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        if let value = canonicalId {
            data[Keys.canonicalId] = value
        }
        if let value = currentId {
            data[Keys.currentId] = value
        }
        if let value = parentId {
            data[Keys.parentId] = value
        }
        if let value = secondParentId {
            data[Keys.secondParentId] = value
        }
        return data
    }
}
