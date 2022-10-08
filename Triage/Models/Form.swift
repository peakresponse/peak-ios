//
//  Form.swift
//  Triage
//
//  Created by Francis Li on 9/15/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation
import RealmSwift

class Form: BaseVersioned {
    struct Keys {
        static let title = "title"
        static let body = "body"
        static let reasons = "reasons"
        static let signatures = "signatures"
    }

    @Persisted var title: String?
    @Persisted var body: String?
    @Persisted var reasonsData: Data?
    @JSONObjectArray(\.reasonsData) @objc var reasons: [[String: Any]]?
    @Persisted var signaturesData: Data?
    @JSONObjectArray(\.signaturesData) @objc var signatures: [[String: Any]]?

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.title] = title
        json[Keys.body] = body
        json[Keys.reasons] = reasons ?? NSNull()
        json[Keys.signatures] = signatures ?? NSNull()
        return json
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        self.title = data[Keys.title] as? String
        self.body = data[Keys.body] as? String
        self.reasons = data[Keys.reasons] as? [[String: Any]]
        self.signatures = data[Keys.signatures] as? [[String: Any]]
    }
}
