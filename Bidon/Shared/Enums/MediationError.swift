//
//  MediationError.swift
//  Bidon
//
//  Created by Bidon Team on 19.04.2023.
//

import Foundation


public enum MediationError: String, Error {
    case noBid
    case noFill
    case unknownAdapter
    case adapterNotInitialized
    case bidTimeoutReached
    case fillTimeoutReached
    case networkError
    case incorrectAdUnitId
    case noAppropriateAdUnitId
    case auctionCancelled
    case adFormatNotSupported
    case unscpecifiedException
    case belowPricefloor
}

