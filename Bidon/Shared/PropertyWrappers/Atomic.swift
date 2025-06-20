//
//  Atomic.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


@propertyWrapper
class Atomic<Value> {
    private let queue = DispatchQueue(label: "com.bidon.atomic.queue")
    private var value: Value

    var projectedValue: Atomic<Value> { self }

    init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    var wrappedValue: Value {
        get {
            return queue.sync { value }
        }
        set {
            queue.sync { value = newValue }
        }
    }

    func mutate(_ mutation: (inout Value) -> ()) {
        return queue.sync {
            mutation(&value)
        }
    }
}


@propertyWrapper
class BarrierAtomic<Value> {
    private let queue = DispatchQueue(label: "com.bidon.barrierAtomic.queue", attributes: .concurrent)
    private var value: Value

    var projectedValue: BarrierAtomic<Value> { self }

    init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    var wrappedValue: Value {
        get {
            return queue.sync { value }
        }
        set {
            queue.sync(flags: .barrier) { value = newValue }
        }
    }

    func mutate(_ mutation: (inout Value) -> ()) {
        queue.sync(flags: .barrier) {
            mutation(&value)
        }
    }
}
