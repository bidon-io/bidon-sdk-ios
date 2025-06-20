//
//  Repository.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 29.06.2022.
//

import Foundation


public final class Repository<Key, Value> where Key: Hashable {
    internal let queue: DispatchQueue
    private var objects: [Key: Any]

    public init(_ queueName: String) {
        objects = [:]
        queue = DispatchQueue(
            label: queueName,
            attributes: .concurrent
        )
    }

    var isEmpty: Bool {
        queue.sync { [unowned self] in
            return self.objects.isEmpty
        }
    }

    var keys: Dictionary<Key, Any>.Keys {
        return queue.sync { [unowned self] in
            return self.objects.keys
        }
    }

    public func removeValue(forKey key: Key) {
        queue.async(flags: .barrier) { [weak self] in
            self?.objects.removeValue(forKey: key)
        }
    }

    public subscript<T>(key: Key) -> T? {
        get { value(key) }
        set { setValue(newValue, key: key) }
    }

    func clear() {
        queue.async(flags: .barrier) { [unowned self] in
            self.objects.removeAll()
        }
    }

    func all<T>() -> [T] {
        queue.sync { [unowned self] in
            return self.objects.values.compactMap { $0 as? T }
        }
    }

    func all<T>(of type: T.Type) -> [T] {
        return all() as [T]
    }

    private func value<T>(_ key: Key) -> T? {
        queue.sync { [unowned self] in
            return self.objects[key] as? T
        }
    }

    private func setValue<T>(_ value: T, key: Key) {
        queue.async(flags: .barrier) { [weak self] in
            self?.objects[key] = value
        }
    }
}
