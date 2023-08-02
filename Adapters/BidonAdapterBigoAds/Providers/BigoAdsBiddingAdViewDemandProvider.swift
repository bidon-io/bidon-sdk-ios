//
//  BigoAdsBiddingAdViewDemandProvider.swift
//  BidonAdapterBigoAds
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import UIKit
import Bidon
import BigoADS


final class BigoAdsBiddingAdViewDemandProvider: BigoAdsBiddingBaseDemandProvider<BigoBannerAd> {
    final class BigoBannerAdContainer: UIView, AdViewContainer {
        let isAdaptive: Bool = false
        
        private(set) weak var ad: BigoBannerAd?
        
        init(ad: BigoBannerAd, size: BigoAdSize) {
            let rect = CGRect(
                x: 0,
                y: 0,
                width: size.width,
                height: size.height
            )
            super.init(frame: rect)
            setup(ad: ad)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setup(ad: BigoBannerAd) {
            self.ad = ad
            let adView = ad.adView()
            
            addSubview(adView)
            adView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                adView.topAnchor.constraint(equalTo: self.topAnchor),
                adView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                adView.leftAnchor.constraint(equalTo: self.leftAnchor),
                adView.rightAnchor.constraint(equalTo: self.rightAnchor)
            ])
        }
    }
    
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    
    private lazy var loader = BigoBannerAdLoader(bannerAdLoaderDelegate: self)
    
    private var response: DemandProviderResponse?
    
    private let format: BannerFormat
    
    private weak var adContainer: BigoBannerAdContainer?
    
    init(context: AdViewContext) {
        self.format = context.format
        super.init()
    }
    
    override func prepareBid(
        data: BigoAdsBiddingBaseDemandProvider<BigoBannerAd>.BiddingResponse,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        
        let request = BigoBannerAdRequest(
            slotId: data.slotId,
            adSizes: [format.bigoAdSize]
        )
        request.setServerBidPayload(data.payload)
        
        loader.loadAd(request)
    }
    
    override func onAdOpened(_ ad: BigoAd) {
        guard let container = adContainer, container.ad === ad else {
            return
        }
        adViewDelegate?.providerWillPresentModalView(self, adView: container)
    }
    
    override func onAdClosed(_ ad: BigoAd) {
        guard let container = adContainer, container.ad === ad else {
            return
        }
        adViewDelegate?.providerDidDismissModalView(self, adView: container)
    }
}


extension BigoAdsBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: BigoBannerAd) -> AdViewContainer? {
        if let container = adContainer, container.ad === ad {
            return container
        }
        
        let container = BigoBannerAdContainer(
            ad: ad,
            size: format.bigoAdSize
        )
        
        self.adContainer = container
        
        return container
    }
    
    func didTrackImpression(for ad: BigoBannerAd) {}
}


extension BigoAdsBiddingAdViewDemandProvider: BigoBannerAdLoaderDelegate {
    func onBannerAdLoaded(_ ad: BigoBannerAd) {
        ad.setAdInteractionDelegate(self)
        
        response?(.success(ad))
        response = nil
    }
    
    func onBannerAdLoadError(_ error: BigoAdError) {
        response?(.failure(MediationError(error: error)))
        response = nil
    }
}


extension BannerFormat {
    var bigoAdSize: BigoAdSize {
        switch self {
        case .banner:
            return .banner()
        case .leaderboard:
            return .large_BANNER()
        case .mrec:
            return .medium_RECTANGLE()
        case .adaptive:
            return .banner()
        }
    }
}
