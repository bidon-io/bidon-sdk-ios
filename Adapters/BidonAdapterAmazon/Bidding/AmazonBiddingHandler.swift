//
//  AmazonBiddingHandler.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 08.11.2023.
//

import Foundation
import Bidon
import DTBiOSSDK

struct AmazonHandlersStorage {
    
    @Atomic
    private static var responses = [String: DTBAdResponse]() // this is evil I know
    
    static func store(_ response: DTBAdResponse, for slotUUID: String) {
        responses[slotUUID] = response
    }
    
    static func fetch(for slotUUID: String) -> DTBAdResponse? {
        return responses[slotUUID]
    }
}


struct AmazonBiddingSlot: Codable {
    var slotUuid: String
    var pricePoint: String
    
    init?(response: DTBAdResponse) {
        guard
            let adSize = response.adSize(),
            let slotUuid = adSize.slotUUID
        else { return nil }
        
        self.slotUuid = slotUuid
        self.pricePoint = response.amznSlots()
    }
}


final class AmazonBiddingHandler: NSObject, DTBAdCallback {
    private var responses: [DTBAdResponse] = []
    private var loaders: [DTBAdLoader] = []
    
    private let adSizes: [DTBAdSize]
    private let group = DispatchGroup()
    
    init(adSizes:[DTBAdSize]) {
        self.adSizes = adSizes
        super.init()
    }
    
    func fetch(response: @escaping (Result<String, MediationError>) -> ()) {
        guard !adSizes.isEmpty else {
            response(.failure(.incorrectAdUnitId))
            return
        }
        
        adSizes.forEach { adSize in
            group.enter()
            let loader = DTBAdLoader(adNetworkInfo: DTBAdNetworkInfo(networkName: DTBADNETWORK_CUSTOM_MEDIATION))
            loader.setAdSizes([adSize])
            loader.loadAd(self)
            loaders.append(loader)
        }
        
        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            
            let slots = self.responses.compactMap { AmazonBiddingSlot(response: $0) }
            guard let context = AmazonBiddingToken(slots: slots) else {
                response(.failure(.noBid("Amazon has not provided bidding token")))
                return
            }
            
            response(.success(context.token))
        }
    }
    
    func onSuccess(_ adResponse: DTBAdResponse!) {
        responses.append(adResponse)
        AmazonHandlersStorage.store(adResponse, for: adResponse.adSize()?.slotUUID ?? "")
        group.leave()
    }
    
    func onFailure(_ error: DTBAdError) {
        group.leave()
    }
    
    func response(for slotUUID: String) -> DTBAdResponse? {
        return responses.first { $0.adSize()?.slotUUID == slotUUID }
    }
}

@propertyWrapper
fileprivate class Atomic<Value> {
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
