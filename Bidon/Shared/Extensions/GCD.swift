//
//  GCD.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


extension DispatchQueue {
    static var bd: DSL { DSL() }

    struct DSL {
        @discardableResult
        func blocking<T>(_ block: @escaping () -> T) -> T {
            if Thread.current.isMainThread {
                return block()
            } else {
                let semaphore = DispatchSemaphore(value: 0)

                var _result: T!

                DispatchQueue.main.async {
                    _result = block()
                    semaphore.signal()
                }
                semaphore.wait()

                return _result
            }
        }
    }
}
