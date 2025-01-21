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
    

    private struct AssociatedKeys {
        static var dst: StaticString = "dst"
    }

    var dst: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.dst) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.dst, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
