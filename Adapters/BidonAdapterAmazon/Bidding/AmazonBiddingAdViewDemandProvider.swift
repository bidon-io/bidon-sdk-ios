//
//  AmazonBiddingAdViewDemandProvider.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 29.09.2023.
//

import Foundation
import Bidon
import DTBiOSSDK


final class AmazonBiddingAdViewDemandProvider: AmazonBiddingDemandProvider<DTBAdBannerDispatcher> {
    weak var adViewDelegate: Bidon.DemandProviderAdViewDelegate?
    var adView: AmazonAdView?
    
    private lazy var dispatcher = DTBAdBannerDispatcher(
        adFrame: CGRect(
            origin: .zero,
            size: self.format.preferredSize
        ),
        delegate: self
    )
    
    private var response: DemandProviderResponse?
    
    let format: BannerFormat
    
    init(
        adSizes: [DTBAdSize],
        context: AdViewContext
    ) {
        self.format = context.format
        super.init(adSizes: adSizes)
    }
    
    override func fill(
        _ data: DTBAdResponse,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        dispatcher.fetchBannerAd(withParameters: data.mediationHints())
    }
}


extension AmazonBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: DTBAdBannerDispatcher) -> AdViewContainer? {
        return adView
    }
    
    func didTrackImpression(for ad: DTBAdBannerDispatcher) {}
}


extension AmazonBiddingAdViewDemandProvider: DTBAdBannerDispatcherDelegate {
    func adDidLoad(_ adView: UIView) {
        self.adView = AmazonAdView(adView: adView)
        response?(.success(dispatcher))
        response = nil
    }
    
    func adFailed(toLoad banner: UIView?, errorCode: Int) {
        response?(.failure(.noFill))
        response = nil
    }
    
    func bannerWillLeaveApplication(_ adView: UIView) {
        guard let container = self.adView else { return }
        adViewDelegate?.providerWillLeaveApplication(self, adView: container)
    }
    
    func adClicked() {
        delegate?.providerDidClick(self)
    }
    
    func impressionFired() {
        revenueDelegate?.provider(self, didLogImpression: dispatcher)
    }
}


final class AmazonAdView: UIView, AdViewContainer {
    var isAdaptive: Bool { false }
    
    init(adView: UIView) {
        super.init(frame: adView.bounds)
        
        adView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(adView)
        
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: self.topAnchor),
            adView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            adView.leftAnchor.constraint(equalTo: self.leftAnchor),
            adView.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
