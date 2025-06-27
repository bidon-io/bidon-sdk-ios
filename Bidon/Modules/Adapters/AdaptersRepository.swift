//
//  AdaptersRepository.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 04.07.2022.
//

import Foundation


internal typealias AdaptersRepository = Repository<String, Adapter>
private var initializedAdaptersKey: UInt8 = 0

extension AdaptersRepository {
    convenience init() {
        self.init("com.bidon.adapters-repository.queue")
    }

    var ids: [String] {
        return Array(keys)
    }

    var initializedIds: Set<String> {
        get {
            objc_getAssociatedObject(self, &initializedAdaptersKey) as? Set<String> ?? []
        }
        set {
            objc_setAssociatedObject(self, &initializedAdaptersKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func register(className: String) {
        if let cls = NSClassFromString(className) as? Adapter.Type {
            let adapter = cls.init()
            Logger.debug("Register \(adapter.name) adapter. Version \(BidonSdk.sdkVersion).\(adapter.adapterVersion). SDK Version: \(adapter.sdkVersion)")
            self[adapter.demandId] = adapter
        } else {
            Logger.error("Adapter with class: \(className) wasn't found")
        }
    }

    func register(adapter: Adapter) {
        Logger.debug("Register \(adapter.name) adapter. Version \(BidonSdk.sdkVersion).\(adapter.adapterVersion). SDK Version: \(adapter.sdkVersion)")
        self[adapter.demandId] = adapter
    }

    func configure() {
        Constants.Adapters.classes.forEach { className in
            if let cls = NSClassFromString(className) as? Adapter.Type {
                let adapter = cls.init()
                Logger.debug("Register \(adapter.name) adapter. Version \(BidonSdk.sdkVersion).\(adapter.adapterVersion). SDK Version: \(adapter.sdkVersion)")
                self[adapter.demandId] = adapter
            }
        }
    }

    func markInitialized(adapter: Adapter) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            var ids = self.initializedIds
            ids.insert(adapter.demandId)
            self.initializedIds = ids
        }
    }
}
