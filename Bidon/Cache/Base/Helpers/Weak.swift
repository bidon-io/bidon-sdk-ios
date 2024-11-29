//
//  Weak.swift
//  Bidon
//
//  Created by Евгения Григорович on 29/11/2024.
//

import Foundation

class Weak<T: AnyObject> {
    weak var value: T?

    init(_ value: T?) {
        self.value = value
    }
}

struct WeakArray {
    private var items = [Weak<AnyObject>]()

    mutating func append(_ object: AnyObject?) {
        cleanUp()
        items.append(Weak(object))
    }

    mutating func remove(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
    }
    
    mutating func removeAll() {
        items.removeAll()
    }

    func compact() -> [AnyObject] {
        return items.compactMap { $0.value }
    }

    private mutating func cleanUp() {
        items.removeAll { $0.value == nil }
    }
}
