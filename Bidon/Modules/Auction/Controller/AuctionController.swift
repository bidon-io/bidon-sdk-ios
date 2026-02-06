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
    typealias AllBidsCompletion = (Result<[BidType], SdkError>) -> ()

    func load(completion: @escaping Completion)

    func load(allBidsCompletion: @escaping AllBidsCompletion)

    func cancel()
}

extension AuctionController {
    func load(allBidsCompletion: @escaping AllBidsCompletion) {
        load { result in
            switch result {
            case .success(let bid):
                allBidsCompletion(.success([bid]))
            case .failure(let error):
                allBidsCompletion(.failure(error))
            }
        }
    }
}
