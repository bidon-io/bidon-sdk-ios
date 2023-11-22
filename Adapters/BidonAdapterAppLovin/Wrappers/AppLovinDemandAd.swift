//
//  ALAdWrapper.swift
//  BidonAdapterAppLovin
//
//  Created by Bidon Team on 25.08.2022.
//

import Foundation
import AppLovinSDK
import Bidon


protocol AppLovinDemandAd: DemandAd {}


extension ALAd: AppLovinDemandAd {
    public var id: String { String(hash) }
}
