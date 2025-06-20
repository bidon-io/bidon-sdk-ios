//
//  BannerView.swift
//  Sandbox
//
//  Created by Bidon Team on 12.10.2022.
//

import Foundation
import SwiftUI
import UIKit
import Combine
import Bidon


struct RawBannerView: UIViewRepresentable, AdBannerWrapperView {
    typealias UIViewType = BannerView

    var format: AdBannerWrapperFormat
    var isAutorefreshing: Bool
    var autorefreshInterval: TimeInterval
    var pricefloor: Price
    var auctionKey: String?
    var onEvent: AdBannerWrapperViewEvent

    @Binding var ad: Bidon.Ad?
    @Binding var isLoading: Bool

    init(
        format: AdBannerWrapperFormat,
        isAutorefreshing: Bool,
        autorefreshInterval: TimeInterval,
        pricefloor: Price = 0.1,
        auctionKey: String?,
        onEvent: @escaping AdBannerWrapperViewEvent,
        ad: Binding<Bidon.Ad?>,
        isLoading: Binding<Bool>
    ) {
        self.format = format
        self.isAutorefreshing = isAutorefreshing
        self.autorefreshInterval = autorefreshInterval
        self.onEvent = onEvent
        self.pricefloor = pricefloor
        self._ad = ad
        self._isLoading = isLoading
        self.auctionKey = auctionKey
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(frame: .zero, auctionKey: auctionKey)

        banner.format = BannerFormat(format)
        banner.rootViewController = UIApplication.shared.bd.topViewcontroller
        banner.delegate = context.coordinator

        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.format = BannerFormat(format)

        if isLoading {
            uiView.loadAd(with: pricefloor, auctionKey: auctionKey)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(
            onEvent: onEvent
        ) {
            self.ad = $0
            self.isLoading = false
        }
    }

    final class Coordinator: BaseAdWrapper {
        private var cancellables = Set<AnyCancellable>()

        override var adType: AdType { .banner }

        init(
            onEvent: @escaping AdBannerWrapperViewEvent,
            onUpdateAd: @escaping (Bidon.Ad?) -> ()
        ) {
            super.init()

            adEventSubject
                .receive(on: RunLoop.main)
                .sink(receiveValue: onEvent)
                .store(in: &cancellables)

            adSubject
                .receive(on: RunLoop.main)
                .sink(receiveValue: onUpdateAd)
                .store(in: &cancellables)
        }
    }
}


extension RawBannerView.Coordinator: Bidon.AdViewDelegate {
    func adView(_ adView: UIView & Bidon.AdView, willPresentScreen ad: Bidon.Ad) {
        send(
            event: "Bidon will present screen",
            detail: ad.text,
            bage: "star.fill",
            color: .accentColor
        )
    }

    func adView(_ adView: UIView & Bidon.AdView, didDismissScreen ad: Bidon.Ad) {
        send(
            event: "Bidon will dismiss screen",
            detail: ad.text,
            bage: "star.fill",
            color: .accentColor
        )
    }

    func adView(_ adView: UIView & Bidon.AdView, willLeaveApplication ad: Bidon.Ad) {
        send(
            event: "Bidon will leave application",
            detail: ad.text,
            bage: "star.fill",
            color: .accentColor
        )
    }
}
