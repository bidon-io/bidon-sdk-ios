//
//  StartIoBiddingAdViewDemandProvider.swift
//  BidonAdapterStartIo
//

import Foundation
import UIKit
import Bidon
import StartApp


final class StartIoAdViewDemandAd: DemandAd {
    public var id: String { return String(adView.hash) }
    public var adView: STABannerViewBase

    init(adView: STABannerViewBase) {
        self.adView = adView
    }
}


final class StartIoBiddingAdViewDemandProvider: StartIoBiddingBaseDemandProvider<StartIoAdViewDemandAd> {
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var rootViewController: UIViewController?

    private var response: Bidon.DemandProviderResponse?
    private var adView: STABannerViewBase?
    private var bannerLoader: STABannerLoader?

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

        let pref = STAAdPreferences()
        pref.adTag = adUnitExtras.tagId

        let loader = STABannerLoader(adPreferences: pref, adm: payload.payload)
        self.bannerLoader = loader

        loader.loadAd { [weak self] creator, error in
            guard let self else { return }

            if let error = error {
                self.response?(.failure(.noFill(error.localizedDescription)))
                self.response = nil
                return
            }

            guard let creator = creator else {
                self.response?(.failure(.noFill("Creator is nil")))
                self.response = nil
                return
            }

            let view = creator.createBannerView(forDelegate: self, supportAutolayout: true)
            self.adView = view

            if let inlineView = view as? STAInlineView {
                inlineView.translatesAutoresizingMaskIntoConstraints = false
            }

            let wrappedAd = StartIoAdViewDemandAd(adView: view)
            self.response?(.success(wrappedAd))
            self.response = nil
        }
    }
}


extension StartIoBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: StartIoAdViewDemandAd) -> Bidon.AdViewContainer? {
        return ad.adView
    }

    func didTrackImpression(for ad: StartIoAdViewDemandAd) {}
}

extension STABannerViewBase: Bidon.AdViewContainer {
    public var isAdaptive: Bool { false }
}

extension StartIoBiddingAdViewDemandProvider: STABannerDelegateProtocol {
    func didDisplayBannerAd(_ banner: STABannerViewBase) {
        // NO-OP: Banner ads don't use providerWillPresent - that's for fullscreen ads only
        let wrappedAd = StartIoAdViewDemandAd(adView: banner)
        revenueDelegate?.provider(self, didLogImpression: wrappedAd)
    }

    func didClickBannerAd(_ banner: STABannerViewBase) {
        delegate?.providerDidClick(self)
    }

    func failedLoadBannerAd(_ banner: STABannerViewBase, withError error: Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
}



