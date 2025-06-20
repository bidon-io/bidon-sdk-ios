//
//  AuctionControllerDelegate.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 06.07.2022.
//

import Foundation


protocol AuctionController {
    associatedtype DemandProviderType: DemandProvider
    associatedtype BidType: Bid where BidType.ProviderType == DemandProviderType

    typealias Completion = (Result<BidType, SdkError>) -> ()

    func load(completion: @escaping Completion)

    func cancel()
}
