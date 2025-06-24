//
//  MainThreadComputable.swift
//  Bidon
//
//  Created by Bidon Team on 30.08.2022.
//

import Foundation


@propertyWrapper
public struct MainThreadComputable<T> {
    private let block: () -> T

    public var wrappedValue: T {
        get {
            guard !Thread.isMainThread else { return block() }
            let semaphore = DispatchSemaphore(value: 0)
            var result: T!
            DispatchQueue.main.async {
                result = block()
                semaphore.signal()
            }
            semaphore.wait()
            return result
        }
    }

    public init(_ block: @escaping @autoclosure () -> T) {
        self.block = block
    }
}
