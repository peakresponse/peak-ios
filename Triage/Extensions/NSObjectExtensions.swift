//
//  NSObjectExtensions.swift
//  Triage
//
//  Created by Francis Li on 9/15/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation

// Source:
// https://gist.github.com/jegnux/4a9871220ef93016d92194ecf7ae8919
@propertyWrapper
public struct AnyProxy<EnclosingSelf, Value> {
    private let keyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>

    public init(_ keyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>) {
        self.keyPath = keyPath
    }

    @available(*, unavailable, message: "The wrapped value must be accessed from the enclosing instance property.")
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    public static subscript(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value {
        get {
            let storageValue = observed[keyPath: storageKeyPath]
            let value = observed[keyPath: storageValue.keyPath]
            return value
        }
        set {
            let storageValue = observed[keyPath: storageKeyPath]
            observed[keyPath: storageValue.keyPath] = newValue
        }
    }
}

@propertyWrapper
public struct AnyJSONObjectArray<EnclosingSelf> {
    private let keyPath: ReferenceWritableKeyPath<EnclosingSelf, Data?>

    public init(_ keyPath: ReferenceWritableKeyPath<EnclosingSelf, Data?>) {
        self.keyPath = keyPath
    }

    @available(*, unavailable, message: "The wrapped value must be accessed from the enclosing instance property.")
    public var wrappedValue: [[String: Any]]? {
        get { fatalError() }
        set { fatalError() }
    }

    public static subscript(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, [[String: Any]]?>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> [[String: Any]]? {
        get {
            let storageValue = observed[keyPath: storageKeyPath]
            if let data = observed[keyPath: storageValue.keyPath] {
                return try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
            }
            return nil
        }
        set {
            let storageValue = observed[keyPath: storageKeyPath]
            if let newValue = newValue {
                observed[keyPath: storageValue.keyPath] = try? JSONSerialization.data(withJSONObject: newValue, options: [])
            } else {
                observed[keyPath: storageValue.keyPath] = nil
            }
        }
    }
}

// Kudos @johnsundell for this trick
// https://swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/
extension NSObject: ProxyContainer {}

public protocol ProxyContainer {
    typealias Proxy<T> = AnyProxy<Self, T>
    typealias JSONObjectArray = AnyJSONObjectArray<Self>
}
