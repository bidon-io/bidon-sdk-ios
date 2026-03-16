//
//  VRtbTokenStore.swift
//  Bidon
//

import Foundation


final class VRTBTokenStore {
    private struct TokenKey: Hashable {
        let demandId: String
        let adType: AdType
    }

    fileprivate struct StoredToken {
        let token: BiddingDemandToken
        let storedAt: Date
    }

    private var storage: [TokenKey: StoredToken] = [:]

    func consumeTokens(adType: AdType) -> [BiddingDemandToken] {
        storage = storage.filter { !$0.value.isExpired }

        let keys = storage.keys.filter { $0.adType == adType }
        let tokens = keys.compactMap { storage[$0]?.token }
        keys.forEach {
            storage.removeValue(forKey: $0)
        }
        if !tokens.isEmpty {
            Logger.vManager("RtbTokenStore: consumed \(tokens.map(\.demandId)) (\(adType))")
        }
        return tokens
    }

    func storeFromRound(_ report: any AuctionReport, adType: AdType) {
        let cancelledDemandIds = Set(
            (report.round.bidding?.demands ?? [])
                .filter { $0.status.isCancelled }
                .map(\.demandId)
        )
        let now = Date()
        for token in report.configuration.tokens {
            guard token.status == .success else {
                continue
            }
            guard cancelledDemandIds.contains(token.demandId) else {
                continue
            }
            let key = TokenKey(demandId: token.demandId, adType: adType)
            storage[key] = StoredToken(token: token, storedAt: now)
            Logger.vManager("RtbTokenStore: stored cancelled \(token.demandId) (\(adType))")
        }
    }
}

private extension VRTBTokenStore.StoredToken {
    var isExpired: Bool {
        Date().timeIntervalSince(self.storedAt) >= Constant.tokenTTL
    }
}

private enum Constant {
    static let tokenTTL: TimeInterval = 15 * 60
}
