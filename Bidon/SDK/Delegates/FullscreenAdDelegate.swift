//
//  FullscreenAdDelegate.swift
//  Bidon
//
//  Created by Bidon Team on 12.08.2022.
//

import Foundation

@objc(BDNFullscreenAd)
public protocol FullscreenAdObject: AdObject {}


@objc(BDNFullscreenAdDelegate)
public protocol FullscreenAdDelegate: AdObjectDelegate {
    func fullscreenAd(_ fullscreenAd: FullscreenAdObject, willPresentAd ad: Ad)
    
    func fullscreenAd(_ fullscreenAd: FullscreenAdObject, didDismissAd ad: Ad)
}
