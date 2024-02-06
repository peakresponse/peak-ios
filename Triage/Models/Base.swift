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

    @Persisted(primaryKey: true) var id = UUID().uuidString.lowercased()
    @Persisted var createdAt: Date?
    @Persisted var updatedAt: Date?

    override required init() {
        super.init()
    }

    convenience init(clone obj: Base) {
        self.init(value: obj)
        id = UUID().uuidString.lowercased()
    }

    func update(from data: [String: Any], with realm: Realm) {
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
        data[Keys.createdAt] = createdAt?.asISO8601String()
        data[Keys.updatedAt] = updatedAt?.asISO8601String()
        return data
    }

    class func instantiate(from data: [String: Any], with realm: Realm) -> Base {
        let obj = self.init()
        obj.update(from: data, with: realm)
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

    @Persisted var canonicalId: String?
    var canonical: BaseVersioned? {
        if let canonicalId = canonicalId {
            let realm = self.realm ?? AppRealm.open()
            return realm.object(ofType: type(of: self), forPrimaryKey: canonicalId)
        }
        return nil
    }
    @Persisted var currentId: String?
    @Persisted var parentId: String?
    var parent: BaseVersioned? {
        if let parentId = parentId {
            let realm = self.realm ?? AppRealm.open()
            return realm.object(ofType: type(of: self), forPrimaryKey: parentId)
        }
        return nil
    }
    @Persisted var secondParentId: String?

    convenience init(clone obj: BaseVersioned) {
        self.init(value: obj)
        id = UUID().uuidString.lowercased()
        if currentId != nil {
            canonicalId = obj.id
            parentId = currentId
            currentId = nil
        } else {
            parentId = obj.id
        }
    }

    convenience init?(current obj: BaseVersioned) {
        self.init(value: obj)
        guard let currentId = currentId else { return nil }
        canonicalId = id
        id = currentId
        parentId = nil
        self.currentId = nil
    }

    convenience init?(canonicalize obj: BaseVersioned) {
        self.init(value: obj)
        guard let canonicalId = canonicalId else { return nil }
        currentId = id
        id = canonicalId
        parentId = nil
        self.canonicalId = nil
    }

    static func newRecord() -> Self {
        let obj = self.init()
        obj.new()
        return obj
    }

    func new() {
        canonicalId = UUID().uuidString.lowercased()
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
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

    func changes(from source: BaseVersioned?) -> [String: Any]? {
        return nil
    }
}
