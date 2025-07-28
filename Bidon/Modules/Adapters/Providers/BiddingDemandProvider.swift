//
//  BiddingDemandProvider.swift
//  Bidon
//
//  Created by Bidon Team on 31.05.2023.
//

import Foundation

public typealias BiddingContextEncoderResponse = (Result<String, MediationError>) -> ()

public protocol GenericBiddingDemandProvider: DemandProvider {
    func collectBiddingTokenEncoder(
        adUnitExtrasDecoder: Decoder,
        response: @escaping BiddingContextEncoderResponse
    )

    func collectBiddingTokenEncoder(
        auctionKey: String?,
        adUnitExtrasDecoder: Decoder,
        response: @escaping BiddingContextEncoderResponse
    )

    func load(
        payloadDecoder: Decoder,
        adUnitExtrasDecoder: Decoder,
        response: @escaping DemandProviderResponse
    )
}

public protocol BiddingDemandProvider: GenericBiddingDemandProvider {
    associatedtype BiddingPayload: Decodable
    associatedtype BiddingTokenExtras: Decodable
    associatedtype AdUnitExtras: Decodable

    func collectBiddingToken(
        biddingTokenExtras: BiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    )

    func collectBiddingToken(
        auctionKey: String?,
        biddingTokenExtras: BiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    )

    func load(
        payload: BiddingPayload,
        adUnitExtras: AdUnitExtras,
        response: @escaping DemandProviderResponse
    )
}

extension BiddingDemandProvider {
    public func collectBiddingToken(
        auctionKey: String?,
        biddingTokenExtras: BiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        collectBiddingToken(
            biddingTokenExtras: biddingTokenExtras,
            response: response
        )
    }

    public func collectBiddingTokenEncoder(
        auctionKey: String?,
        adUnitExtrasDecoder: Decoder,
        response: @escaping BiddingContextEncoderResponse
    ) {
        do {
            let biddingTokenExtras = try BiddingTokenExtras(from: adUnitExtrasDecoder)
            collectBiddingToken(
                auctionKey: auctionKey,
                biddingTokenExtras: biddingTokenExtras,
                response: response
            )
        } catch {
            response(.failure(.incorrectAdUnitId))
        }
    }

    public func collectBiddingTokenEncoder(
        adUnitExtrasDecoder: Decoder,
        response: @escaping BiddingContextEncoderResponse
    ) {
        collectBiddingTokenEncoder(
            auctionKey: nil,
            adUnitExtrasDecoder: adUnitExtrasDecoder,
            response: response
        )
    }

    public func load(
        payloadDecoder: Decoder,
        adUnitExtrasDecoder: Decoder,
        response: @escaping DemandProviderResponse
    ) {
        do {
            let payload = try BiddingPayload(from: payloadDecoder)
            let adUnitExtras = try AdUnitExtras(from: adUnitExtrasDecoder)

            load(
                payload: payload,
                adUnitExtras: adUnitExtras,
                response: response
            )
        } catch {
            response(.failure(.incorrectAdUnitId))
        }
    }
}

final class BiddingDemandProviderWrapper<W>: DemandProviderWrapper<W>, GenericBiddingDemandProvider {
    private let _collectBiddingTokenEncoder: (String?, Decoder, @escaping BiddingContextEncoderResponse) -> ()
    private let _load: (Decoder, Decoder, @escaping DemandProviderResponse) -> ()

    override init(_ wrapped: W) throws {
        guard let _wrapped = wrapped as? (any GenericBiddingDemandProvider)
        else { throw SdkError.internalInconsistency }

        _collectBiddingTokenEncoder = { _wrapped.collectBiddingTokenEncoder(auctionKey: $0, adUnitExtrasDecoder: $1, response: $2) }
        _load = { _wrapped.load(payloadDecoder: $0, adUnitExtrasDecoder: $1, response: $2) }

        try super.init(wrapped)
    }

    func collectBiddingTokenEncoder(
        auctionKey: String?,
        adUnitExtrasDecoder: Decoder,
        response: @escaping BiddingContextEncoderResponse
    ) {
        _collectBiddingTokenEncoder(auctionKey, adUnitExtrasDecoder, response)
    }

    func collectBiddingTokenEncoder(
        adUnitExtrasDecoder: Decoder,
        response: @escaping BiddingContextEncoderResponse
    ) {
        _collectBiddingTokenEncoder(nil, adUnitExtrasDecoder, response)
    }

    func load(
        payloadDecoder: Decoder,
        adUnitExtrasDecoder: Decoder,
        response: @escaping DemandProviderResponse
    ) {
        _load(payloadDecoder, adUnitExtrasDecoder, response)
    }
}
