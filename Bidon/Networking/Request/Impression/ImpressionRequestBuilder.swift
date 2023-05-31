//
//  ImpressionRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


protocol ImpressionRequestBuilder: BaseRequestBuilder {
    var imp: ImpressionModel { get }
    var route: Route { get }
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self
    
    @discardableResult
    func withPath(_ path: Route) -> Self
    
    init()
}


final class InterstitialImpressionRequestBuilder: BaseRequestBuilder, ImpressionRequestBuilder {
    var imp: ImpressionModel {
        ImpressionModel(
            _imp,
            interstitial: InterstitialModel()
        )
    }
    
    var route: Route {
        _route
    }
    
    private var _imp: Impression!
    private var _route: Route!
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self {
        self._imp = impression
        return self
    }
    
    @discardableResult
    func withPath(_ path: Route) -> Self {
        self._route = .complex(.adType(.interstitial), path)
        return self
    }
}


final class RewardedImpressionRequestBuilder: BaseRequestBuilder, ImpressionRequestBuilder {
    var imp: ImpressionModel {
        ImpressionModel(
            _imp,
            rewarded: RewardedModel()
        )
    }
    
    var route: Route {
        _route
    }
    
    private var _imp: Impression!
    private var _route: Route!
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self {
        self._imp = impression
        return self
    }
    
    @discardableResult
    func withPath(_ path: Route) -> Self {
        self._route = .complex(.adType(.rewarded), path)
        return self
    }
}


final class AdViewImpressionRequestBuilder: BaseRequestBuilder, ImpressionRequestBuilder {
    var imp: ImpressionModel {
        ImpressionModel(
            _imp,
            banner: BannerModel(
                format: _format
            )
        )
    }
    
    var route: Route {
        _route
    }
    
    private var _imp: Impression!
    private var _route: Route!
    private var _format: BannerFormat!
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self {
        self._imp = impression
        return self
    }
    
    @discardableResult
    func withFormat(_ format: BannerFormat) -> Self {
        self._format = format
        return self
    }
    
    @discardableResult
    func withPath(_ path: Route) -> Self {
        self._route = .complex(.adType(.banner), path)
        return self
    }
}
