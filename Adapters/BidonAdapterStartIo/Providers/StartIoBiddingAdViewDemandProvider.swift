//
//  StartIoBiddingAdViewDemandProvider.swift
//  BidonAdapterStartIo
//

import Foundation
import UIKit
import Bidon


final class StartIoBannerContainerView: UIView {}


final class StartIoAdViewDemandAd: DemandAd {
    public let id: String
    public var adView: StartIoBannerContainerView

    init(unitId: String, adView: StartIoBannerContainerView) {
        self.id = unitId
        self.adView = adView
    }
}


final class StartIoBiddingAdViewDemandProvider: StartIoBiddingBaseDemandProvider<StartIoAdViewDemandAd> {
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var rootViewController: UIViewController?

    private var response: Bidon.DemandProviderResponse?
    private var adView: StartIoBannerContainerView?
    private var unitId: String = ""

    init(
        context: AdViewContext
    ) {
        self.rootViewController = context.rootViewController
        super.init()
    }

    override func load(
        payload: StartIoBiddingResponse,
        adUnitExtras: StartIoAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        guard rootViewController != nil else {
            response(.failure(.unspecifiedException("View Controller is nil")))
            return
        }
        self.response = response
        self.unitId = adUnitExtras.adUnitId

        // Placeholder implementation; integrate Start.io banner here
        let banner = StartIoBannerContainerView(frame: .zero)
        self.adView = banner

        let wrappedAd = StartIoAdViewDemandAd(unitId: unitId, adView: banner)
        response(.success(wrappedAd))
        self.response = nil
    }
}


extension StartIoBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: StartIoAdViewDemandAd) -> Bidon.AdViewContainer? {
        return ad.adView
    }

    func didTrackImpression(for ad: StartIoAdViewDemandAd) {
        // Integrate impression tracking with Start.io when available
    }
}


extension StartIoBannerContainerView: Bidon.AdViewContainer {
    public var isAdaptive: Bool { false }
}


