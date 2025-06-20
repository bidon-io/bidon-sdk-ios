//
//  GoogleMobileAdsBannerContainerView.swift
//  BidonAdapterGoogleAdManager
//
//  Created by Stas Kochkin on 05.12.2023.
//

import Foundation
import UIKit
import GoogleMobileAds
import Bidon


internal protocol GoogleMobileAdsBannerContainerView: UIView, Bidon.AdViewContainer {
    init(frame: CGRect, adSize: GoogleMobileAds.AdSize)

    func layout(_ banner: GoogleMobileAds.BannerView)
}


final class GoogleMobileAdsAdaptiveBannerContainerView: UIView, GoogleMobileAdsBannerContainerView {
    let isAdaptive: Bool = true

    init(frame: CGRect, adSize: GoogleMobileAds.AdSize) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout(_ banner: GoogleMobileAds.BannerView) {
        addSubview(banner)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: topAnchor),
            banner.leftAnchor.constraint(equalTo: leftAnchor),
            banner.rightAnchor.constraint(equalTo: rightAnchor),
            banner.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard let superview = superview else { return }

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            leftAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leftAnchor),
            rightAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.rightAnchor)
        ])
    }
}


final class GoogleMobileAdsFixedBannerContainerView: UIView, GoogleMobileAdsBannerContainerView {
    let isAdaptive: Bool = false

    private let adSize: GoogleMobileAds.AdSize

    init(frame: CGRect, adSize: GoogleMobileAds.AdSize) {
        self.adSize = adSize
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout(_ banner: GoogleMobileAds.BannerView) {
        addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview = superview else { return }
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: adSize.size.height),
            widthAnchor.constraint(equalToConstant: adSize.size.width),
            centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            centerYAnchor.constraint(equalTo: superview.centerYAnchor)
        ])
    }
}
