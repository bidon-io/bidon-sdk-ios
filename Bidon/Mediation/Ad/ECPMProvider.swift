//
//  ECPMProvider.swift
//  Bidon
//
//  Created by Bidon Team on 29.03.2023.
//

import Foundation


protocol ECPMProvider {
    var ad: DemandAd { get }
    var lineItem: LineItem? { get }
}


extension ECPMProvider {
    var eCPM: Price {
        ad.eCPM ?? lineItem?.pricefloor ?? .unknown
    }
}

