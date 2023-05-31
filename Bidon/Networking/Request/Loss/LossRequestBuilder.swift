//
//  LossRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 05.04.2023.
//

import Foundation


protocol LossRequestBuilder: BaseRequestBuilder {
    var imp: ImpressionModel { get }
    var externalWinner: LossRequest.ExternalWinner { get }
    var route: Route { get }
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self
    
    @discardableResult
    func withExternalWinner(demandId: String, eCPM: Price) -> Self
    
    init()
}


final class InterstitialLossRequestBuilder: BaseRequestBuilder, LossRequestBuilder {
    var imp: ImpressionModel { _imp }
    
    var externalWinner: LossRequest.ExternalWinner { _externalWinner }
    
    var route: Route { .complex(.adType(.interstitial), .loss) }
    
    private(set) var _imp: ImpressionModel!
    private(set) var _externalWinner: LossRequest.ExternalWinner!
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self {
        self._imp = ImpressionModel(
            impression,
            interstitial: InterstitialModel()
        )
        return self
    }
    
    @discardableResult
    func withExternalWinner(
        demandId: String,
        eCPM: Price
    ) -> Self {
        self._externalWinner = .init(
            ecpm: eCPM,
            demandId: demandId
        )
        return self
    }
}


final class RewardedLossRequestBuilder: BaseRequestBuilder, LossRequestBuilder {
    var imp: ImpressionModel { _imp }
    
    var externalWinner: LossRequest.ExternalWinner { _externalWinner }
    
    var route: Route { .complex(.adType(.rewarded), .loss) }
    
    private(set) var _imp: ImpressionModel!
    private(set) var _externalWinner: LossRequest.ExternalWinner!
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self {
        self._imp = ImpressionModel(
            impression,
            rewarded: RewardedModel()
        )
        return self
    }
    
    @discardableResult
    func withExternalWinner(
        demandId: String,
        eCPM: Price
    ) -> Self {
        self._externalWinner = .init(
            ecpm: eCPM,
            demandId: demandId
        )
        return self
    }
}


final class AdViewLossRequestBuilder: BaseRequestBuilder, LossRequestBuilder {
    var imp: ImpressionModel {
        ImpressionModel(
            _imp,
            banner: BannerModel(
                format: _format
            )
        )
    }
    
    var externalWinner: LossRequest.ExternalWinner { _externalWinner }

    var route: Route { .complex(.adType(.banner), .loss) }
    
    private var _imp: Impression!
    private(set) var _externalWinner: LossRequest.ExternalWinner!
    private var _format: BannerFormat!
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self {
        self._imp = impression
        return self
    }
    
    @discardableResult
    func withExternalWinner(
        demandId: String,
        eCPM: Price
    ) -> Self {
        self._externalWinner = .init(
            ecpm: eCPM,
            demandId: demandId
        )
        return self
    }
    
    @discardableResult
    func withFormat(_ format: BannerFormat) -> Self {
        self._format = format
        return self
    }
}
