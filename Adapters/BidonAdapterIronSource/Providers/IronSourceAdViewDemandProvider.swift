//
//  IronSourceAdViewDemandProvider.swift
//  BidonAdapterIronSource
//
//  Created by Евгения Григорович on 12/08/2024.
//

import Foundation
import Bidon
import IronSource

final class IronSourceBannerDemandAd: DemandAd {
    public var id: String

    init(id: String) {
        self.id = id
    }
}

final class IronSourceAdViewDemandProvider: IronSourceBaseDemandProvider<IronSourceBannerDemandAd> {
    private var response: DemandProviderResponse?
    weak var adViewDelegate: DemandProviderAdViewDelegate?

    let context: AdViewContext

    var size: ISBannerSize {
        switch context.format {
        case .banner:
            return ISBannerSize(description: kSizeBanner, width: 320, height: 50)
        case .leaderboard:
            return ISBannerSize(description: kSizeLarge, width: 728, height: 90)
        case .mrec:
            return ISBannerSize(description: kSizeRectangle, width: 300, height: 250)
        case .adaptive:
            return ISBannerSize(description: kSizeSmart, width: Int(context.format.preferredSize.width), height: Int(context.format.preferredSize.height))
        }
    }

    init(context: AdViewContext, api: IronSourceApi) {
        self.context = context
        super.init(api: api)
    }

    override func load(
        pricefloor: Price,
        adUnitExtras: IronSourceAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        guard let viewController = context.rootViewController else {
            response(.failure(.unspecifiedException("View Controller is nil")))
            return
        }
        self.response = response

        api.loadBanner(
            instanceId: adUnitExtras.instanceId,
            viewController: viewController,
            delegate: self,
            size: size
        )
    }
}

extension IronSourceAdViewDemandProvider: AdViewDemandProvider {

    func container(for ad: IronSourceBannerDemandAd) -> Bidon.AdViewContainer? {
        return api.bannerView(for: ad.id)
    }

    func didTrackImpression(for ad: IronSourceBannerDemandAd) { }
}

extension IronSourceAdViewDemandProvider: ISDemandOnlyBannerDelegate {

    func bannerDidLoad(_ bannerView: ISDemandOnlyBannerView!, instanceId: String!) {
        let ad = IronSourceBannerDemandAd(id: instanceId)
        response?(.success(ad))
        response = nil
    }

    func bannerDidFailToLoadWithError(_ error: Error!, instanceId: String!) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func didClickBanner(_ instanceId: String!) {
        delegate?.providerDidClick(self)
    }

    func bannerWillLeaveApplication(_ instanceId: String!) {}
    func bannerDidShow(_ instanceId: String!) {
        delegate?.providerWillPresent(self)

        let ad = IronSourceBannerDemandAd(id: instanceId)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
}

extension ISDemandOnlyBannerView: AdViewContainer {
    public var isAdaptive: Bool {
        return false
    }
}
