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
    
    private let request: GADRequest
    private var response: DemandProviderResponse?
    
    init(_ request: GADRequest) {
        self.request = request
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
}


extension GoogleMobileAdsBaseDemandProvider: DirectDemandProvider {
    func load(_ adUnitId: String, response: @escaping DemandProviderResponse) {
        self.response = response
        loadAd(request, adUnitId: adUnitId)
    }
    
    func notify(ad: AdObject, event: AuctionEvent) {}
}

