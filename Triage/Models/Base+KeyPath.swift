//
//  Base+KeyPath.swift
//  Triage
//
//  Created by Francis Li on 2/10/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation
internal import Realm
internal import RealmSwift

let indexExpr = try! NSRegularExpression(pattern: #"([^\[]+)\[(\d+)\]"#, options: [.caseInsensitive])

extension Base {
    func listObjectAndKeyPath(forKeyPath keyPath: String) -> (NSObject?, String?)? {
        if keyPath.contains("[") {
            var listKeys: [String] = []
            var listIndex: Int?
            var attributeKeys: [String] = []
            let keys = keyPath.split(separator: ".").map { String($0) }
            for key in keys {
                if listIndex == nil {
                    if let match = indexExpr.firstMatch(in: key, options: [], range: NSRange(location: 0, length: key.count)) {
                        if let range = Range(match.range(at: 1), in: key) {
                            listKeys.append(String(key[range]))
                        }
                        if let range = Range(match.range(at: 2), in: key) {
                            listIndex = Int(String(key[range]))
                        }
                    } else {
                        listKeys.append(key)
                    }
                } else {
                    attributeKeys.append(key)
                }
            }
            if let listIndex = listIndex, let list = super.value(forKeyPath: listKeys.joined(separator: ".")) as? RLMSwiftCollectionBase {
                if listIndex < list._rlmCollection.count {
                    let obj = list._rlmCollection.object(at: UInt(listIndex)) as? NSObject
                    if attributeKeys.count > 0 {
                        return (obj, attributeKeys.joined(separator: "."))
                    }
                    return (obj, nil)
                }
            }
            return (nil, nil)
        }
        return nil
    }

    override func setValue(_ value: Any?, forKeyPath keyPath: String) {
        if let (obj, keyPath) = listObjectAndKeyPath(forKeyPath: keyPath) {
            if let keyPath = keyPath {
                obj?.setValue(value, forKeyPath: keyPath)
            }
            return
        }
        super.setValue(value, forKeyPath: keyPath)
    }

    override func value(forKeyPath keyPath: String) -> Any? {
        if let (obj, keyPath) = listObjectAndKeyPath(forKeyPath: keyPath) {
            if let keyPath = keyPath {
                return obj?.value(forKeyPath: keyPath)
            }
            return obj
        }
        return super.value(forKeyPath: keyPath)
    }
}
