//
//  NotificationRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 05.04.2023.
//

import Foundation


protocol NotificationRequestBuilder: AdTypeContextRequestBuilder {
    var imp: ImpressionModel { get }
    var externalWinner: NotificationRequest.ExternalWinner? { get }
    var route: Route { get }
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self
    
    @discardableResult
    func withRoute(_ route: Route) -> Self
    
    @discardableResult
    func withExternalWinner(demandId: String, eCPM: Price) -> Self
        
    init()
}


class BaseNotificationRequestBuilder<Context: AdTypeContext>: BaseRequestBuilder, NotificationRequestBuilder {
    private(set) var impression: Impression!
    private(set) var context: Context!

    private var _externalWinner: NotificationRequest.ExternalWinner?
    private var _route: Route!
    
    var route: Route { .complex(.adType(adType), _route) }
    var externalWinner: NotificationRequest.ExternalWinner? { _externalWinner }

    var imp: ImpressionModel { fatalError("BaseLossRequestBuilder doesn't provide ad imp") }
    var adType: AdType { context.adType }
    
    @discardableResult
    func withImpression(_ impression: Impression) -> Self {
        self.impression = impression
        return self
    }
    
    @discardableResult
    func withRoute(_ route: Route) -> Self {
        self._route = route
        return self
    }
    
    @discardableResult
    func withExternalWinner(demandId: String, eCPM: Price) -> Self {
        self._externalWinner = NotificationRequest.ExternalWinner(
            ecpm: eCPM,
            demandId: demandId
        )
        return self
    }
    
    @discardableResult
    func withAdTypeContext(_ context: Context) -> Self {
        self.context = context
        return self
    }
    
    required override init() {
        super.init()
    }
}
