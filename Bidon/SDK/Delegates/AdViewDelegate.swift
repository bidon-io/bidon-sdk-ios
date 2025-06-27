//
//  BannerViewDelegate.swift
//  Bidon
//
//  Created by Bidon Team on 12.08.2022.
//

import Foundation
import UIKit


@objc(BDNAdView)
public protocol AdView: AdObject {}


@objc(BDNAdViewDelegate)
public protocol AdViewDelegate: AdObjectDelegate {
    func adView(
        _ adView: AdView & UIView,
        willPresentScreen ad: Ad
    )

    func adView(
        _ adView: AdView & UIView,
        didDismissScreen ad: Ad
    )

    func adView(
        _ adView: AdView & UIView,
        willLeaveApplication ad: Ad
    )
}
