//
//  AppLovinRewardWrapper.swift
//  BidonAdapterAppLovin
//
//  Created by Bidon Team on 27.02.2023.
//

import Foundation
import Bidon


typealias AppLovinRewardWrapper = RewardWrapper<[AnyHashable: Any]>

extension AppLovinRewardWrapper {
    convenience init(_ response: [AnyHashable: Any]) {
        let label = (response["currency"] as? String) ?? ""
        let amount = (response["amount"] as? Int) ?? .zero

        self.init(
            label: label,
            amount: amount,
            wrapped: response
        )
    }
}
