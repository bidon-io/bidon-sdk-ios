//
//  GoogleMobileAdsBaseDemandProvider.swift
//  BidonAdapterGoogleMobileAds
//
//  Created by Bidon Team on 23.02.2023.
//

import Foundation
import UIKit
import GoogleMobileAds
import Bidon


class GoogleMobileAdsBaseDemandProvider<AdObject: GoogleMobileAdsDemandAd>: NSObject {
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    private var response: DemandProviderResponse?
    
    let serverData: GoogleMobileAdsDemandSourceAdapter.ServerData
    
    @Injected(\.context)
    var context: Bidon.SdkContext
    
    init(serverData: GoogleMobileAdsDemandSourceAdapter.ServerData) {
        self.serverData = serverData
        super.init()
    }
    
    open func loadAd(_ request: GADRequest, adUnitId: String) {
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


extension GoogleMobileAdsBaseDemandProvider: DirectDemandProvider {
    func load(_ adUnitId: String, response: @escaping DemandProviderResponse) {
        self.response = response
        let request = GADRequest { builder in
            builder.withRequestAgent(serverData.requestAgent)
            builder.withGDPRConsent(context.regulations.gdrpConsent)
            builder.withUSPrivacyString(context.regulations.usPrivacyString)
        }
        
        loadAd(request, adUnitId: adUnitId)
    }
}


extension GoogleMobileAdsBaseDemandProvider: ParameterizedBiddingDemandProvider {
    struct BiddingContext: Codable {
        var token: String
    }
    
    struct BiddingResponse: Codable {
        var payload: String
        var adUnitId: String
    }
    
    func fetchBiddingContext(
        response: @escaping (Result<BiddingContext, Bidon.MediationError>) -> ()
    ) {
        let request = GADRequest { builder in
            builder.withQueryType(serverData.queryInfoType)
            builder.withRequestAgent(serverData.requestAgent)
            builder.withGDPRConsent(context.regulations.gdrpConsent)
            builder.withUSPrivacyString(context.regulations.usPrivacyString)
        }

        GADQueryInfo.createQueryInfo(with: request, adFormat: AdObject.adFormat) { info, error in
            guard let token = info?.query else {
                response(.failure(.adapterNotInitialized))
                return
            }
            
            let context = BiddingContext(token: token)
            response(.success(context))
        }
    }
    
    func prepareBid(
        data: BiddingResponse,
        response: @escaping DemandProviderResponse
    ) {
        let request = GADRequest { builder in
            builder.withQueryType(serverData.queryInfoType)
            builder.withRequestAgent(serverData.requestAgent)
            builder.withGDPRConsent(context.regulations.gdrpConsent)
            builder.withUSPrivacyString(context.regulations.usPrivacyString)
            builder.withBiddingPayload(data.payload)
        }
        
        loadAd(request, adUnitId: data.adUnitId)
    }
}
