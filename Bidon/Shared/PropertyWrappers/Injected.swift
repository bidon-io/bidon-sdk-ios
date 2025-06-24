//
//  Injected.swift
//  Bidon
//
//  Created by Bidon Team on 11.08.2022.
//

import Foundation


public protocol InjectionKey {
    associatedtype Value

    static var currentValue: Self.Value { get set }
}


public struct InjectedValues {
    private static var current = InjectedValues()

    public static subscript<K>(key: K.Type) -> K.Value where K: InjectionKey {
        get { key.currentValue }
        set { key.currentValue = newValue }
    }

    public static subscript<T>(_ keyPath: WritableKeyPath<InjectedValues, T>) -> T {
        get { current[keyPath: keyPath] }
        set { current[keyPath: keyPath] = newValue }
    }
}


@propertyWrapper
public struct Injected<T> {
    private let keyPath: WritableKeyPath<InjectedValues, T>

    public var wrappedValue: T {
        get { InjectedValues[keyPath] }
        set { InjectedValues[keyPath] = newValue }
    }

    public init(_ keyPath: WritableKeyPath<InjectedValues, T>) {
        self.keyPath = keyPath
    }
}
