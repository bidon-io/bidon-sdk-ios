//
//  DTExchangeAdWrapper.swift
//  BidonAdapterDTExchange
//
//  Created by Bidon Team on 27.02.2023.
//

import Foundation
import Bidon
import IASDKCore


protocol DTExchangeDemandAd: DemandAd {}


extension IAAdSpot: DemandAd {
    public var id: String { adRequest.unitID ?? String(hash) }
}
