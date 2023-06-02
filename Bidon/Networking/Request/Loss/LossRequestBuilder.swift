//
//  LossRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 05.04.2023.
//

import Foundation


protocol LossRequestBuilder: BaseRequestBuilder {
    associatedtype Context: AuctionContext
    
    var imp: ImpressionModel { get }
    var externalWinner: LossRequest.ExternalWinner { get }
    var route: Route { get }
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self
    
    @discardableResult
    func withExternalWinner(demandId: String, eCPM: Price) -> Self
    
    @discardableResult
    func withContext(_ context: Context) -> Self
    
    init()
}


class BaseLossRequestBuilder<Context: AuctionContext>: BaseRequestBuilder, LossRequestBuilder {
    private(set) var impression: Impression!
    private(set) var context: Context!

    private var _externalWinner: LossRequest.ExternalWinner!

    var route: Route { .complex(.adType(adType), .loss) }
    var externalWinner: LossRequest.ExternalWinner { _externalWinner }

    var imp: ImpressionModel { fatalError("BaseLossRequestBuilder doesn't provide ad imp") }
    var adType: AdType { fatalError("BaseLossRequestBuilder doesn't provide ad type") }
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self {
        self.impression = impression
        return self
    }
    
    @discardableResult
    func withExternalWinner(demandId: String, eCPM: Price) -> Self {
        self._externalWinner = LossRequest.ExternalWinner(
            ecpm: eCPM,
            demandId: demandId
        )
        return self
    }
    
    @discardableResult
    func withContext(_ context: Context) -> Self {
        self.context = context
        return self
    }
    
    required override init() {
        super.init()
    }
}
