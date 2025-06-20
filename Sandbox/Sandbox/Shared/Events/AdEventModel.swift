//
//  EventModel.swift
//  Sandbox
//
//  Created by Bidon Team on 26.08.2022.
//

import Foundation
import Bidon
import SwiftUI


struct AdEventModel: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var adType: AdType
    var title: String
    var subtitle: String
    var bage: String
    var color: Color
}


extension AdType {
    var title: String {
        switch self {
        case .banner: return "[Banner]"
        case .interstitial: return "[Interstitial]"
        case .rewardedAd: return "[Rewarded Ad]"
        }
    }
}


extension AdBidType {
    var title: String {
        switch self {
        case .cpm: return "CPM"
        case .rtb: return "RTB"
        }
    }
}


extension Price {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")

        return formatter
    }()

    var pretty: String {
        isUnknown ? "-" : Price.formatter.string(from: self as NSNumber) ?? "-"
    }
}


extension Ad {
    var text: String {
        "Ad \(adUnit.label) from \(networkName), eCPM: \(price.pretty)"
    }
}


private extension Reward {
    var text: String {
        "Reward \(amount) of \(label)"
    }
}
