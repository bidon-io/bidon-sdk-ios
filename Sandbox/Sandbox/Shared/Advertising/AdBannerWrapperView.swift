//
//  AdBannerWrapperView.swift
//  Sandbox
//
//  Created by Bidon Team on 17.02.2023.
//

import Foundation
import SwiftUI
import Bidon


enum AdBannerWrapperFormat: String, CaseIterable {
    case banner
    case leaderboard
    case mrec
    case adaptive
    
    var preferredSize: CGSize {
        switch self {
        case .banner:
            return CGSize(width: 320, height: 50)
        case .leaderboard:
            return CGSize(width: 728, height: 90)
        case .mrec:
            return CGSize(width: 300, height: 250)
        case .adaptive:
            return UIDevice.bd.isPhone ?
            CGSize(width: 320, height: 50) :
            CGSize(width: 728, height: 90)
        }
    }
}


typealias AdBannerWrapperViewEvent = (AdEventModel) -> ()


protocol AdBannerWrapperView: View {
    var format: AdBannerWrapperFormat { get set }
    var isAutorefreshing: Bool { get set }
    var autorefreshInterval: TimeInterval { get set }
    var pricefloor: Double { get set }
    var auctionKey: String? { get set }
    var onEvent: AdBannerWrapperViewEvent { get set }
}


struct AnyAdBannerWrapperView: AdBannerWrapperView {
    var mediation: Mediation = AdServiceProvider.shared.service.mediation
    var format: AdBannerWrapperFormat
    var isAutorefreshing: Bool
    var autorefreshInterval: TimeInterval
    var pricefloor: Double
    var auctionKey: String?
    var onEvent: AdBannerWrapperViewEvent
    
    @Binding var ad: Bidon.Ad?
    @Binding var isLoading: Bool
    
    var body: some View {
        switch mediation {
        case .appodeal:
            Color.black
// MARK: DROP_APD_SUPPORT
//            AppodealBannerView(
//                format: format,
//                isAutorefreshing: isAutorefreshing,
//                autorefreshInterval: autorefreshInterval,
//                auctionKey: auctionKey, onEvent: onEvent,
//                ad: $ad,
//                isLoading: $isLoading
//            )
        case .none:
            RawBannerView(
                format: format,
                isAutorefreshing: isAutorefreshing,
                autorefreshInterval: autorefreshInterval,
                pricefloor: pricefloor,
                auctionKey: auctionKey,
                onEvent: onEvent,
                ad: $ad,
                isLoading: $isLoading
            )
        }
    }
}


extension Bidon.BannerFormat {
    init(_ format: AdBannerWrapperFormat) {
        switch format {
        case .banner: self = .banner
        case .leaderboard: self = .leaderboard
        case .mrec: self = .mrec
        case .adaptive: self = .adaptive
        }
    }
}
