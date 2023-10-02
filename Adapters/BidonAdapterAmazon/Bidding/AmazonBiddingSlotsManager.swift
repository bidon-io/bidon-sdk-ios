//
//  AmazonBiddingSlotsManager.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 29.09.2023.
//

import Foundation
import Bidon
import DTBiOSSDK


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


struct AmazonBiddingSlots: Codable {
    var token: String
    
    init?(slots: [AmazonBiddingSlot]) {
        guard
            !slots.isEmpty,
            let data = try? JSONEncoder().encode(slots),
            let token = String(data: data, encoding: .utf8)
        else { return nil }
        
        self.token = token
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
    
    func fetch(response: @escaping (Result<AmazonBiddingSlots, MediationError>) -> ()) {
        adSizes.forEach { adSize in
            group.enter()
            let loader = DTBAdLoader()
            loader.setAdSizes([adSize])
            loader.loadAd(self)
            loaders.append(loader)
        }
        
        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            
            let slots = self.responses.compactMap { AmazonBiddingSlot(response: $0) }
            guard let context = AmazonBiddingSlots(slots: slots) else {
                response(.failure(.noBid))
                return
            }
            
            response(.success(context))
        }
    }
    
    func onSuccess(_ adResponse: DTBAdResponse!) {
        responses.append(adResponse)
        group.leave()
    }
    
    func onFailure(_ error: DTBAdError) {
        group.leave()
    }
    
    func response(for slotUUID: String) -> DTBAdResponse? {
        return responses.first { $0.adSize()?.slotUUID == slotUUID }
    }
}
