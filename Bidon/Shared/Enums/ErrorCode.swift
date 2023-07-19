//
//  ErrorCode.swift
//  Bidon
//
//  Created by Bidon Team on 12.04.2023.
//

import Foundation


@objc(BDNErrorCode)
public enum ErrorCode: Int {
    case sdkNotInitialized = 1
    case appKeyIsInvalid
    case internalServerSdkError
    case networkError
    case auctionInProgress
    case noAuctionResults
    case noRoundResults
    case noContextFound
    case noBid
    case noFill
    case bidTimedOut
    case fillTimedOut
    case adFormatIsNotSupported
    case unspecified
    case adNotReady
    case noAppropriateAdUnitId
    case expired
}


extension ErrorCode {
    static let domain = "org.bidon.error"
}
