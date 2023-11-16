//
//  GoogleAdManagerBaseDemandProvider.swift
//  BidonAdapterGoogleAdManager
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation
import UIKit
import GoogleMobileAds
import Bidon


class GoogleAdManagerBaseDemandProvider<AdObject: GoogleAdManagerDemandAd>: NSObject {
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    private var response: DemandProviderResponse?
    
    let serverData: GoogleAdManagerDemandSourceAdapter.ServerData
    
    @Injected(\.context)
    var context: Bidon.SdkContext
    
    init(serverData: GoogleAdManagerDemandSourceAdapter.ServerData) {
        self.serverData = serverData
        super.init()
    }
    
    open func loadAd(_ request: GAMRequest, adUnitId: String) {
        fatalError("Base demand provider can't load any ad")
    }
    
    final func handleDidLoad(adObject: AdObject) {
        self.response?(.success(adObject))
        self.response = nil
    }
    
    final func handleDidFailToLoad(_ error: MediationError) {
        self.response?(.failure(error))
        self.response = nil
    }
    
    final func setupAdRevenueHandler(adObject: AdObject) {
        adObject.paidEventHandler = { [weak self, weak adObject] value in
            guard let self = self, let adObject = adObject else { return }
                        
            self.revenueDelegate?.provider(
                self,
                didPayRevenue: value.revenue,
                ad: adObject
            )
        }
    }
    
    func notify(
        ad: AdObject,
        event: AuctionEvent
    ) {}
}


extension GoogleAdManagerBaseDemandProvider: DirectDemandProvider {
    func load(_ adUnitId: String, response: @escaping DemandProviderResponse) {
        self.response = response
        let request = GAMRequest { builder in
            builder.withRequestAgent(serverData.requestAgent)
            builder.withGDPRConsent(context.regulations.gdrpConsent)
            builder.withUSPrivacyString(context.regulations.usPrivacyString)
        }
        
        loadAd(request, adUnitId: adUnitId)
    }
}
