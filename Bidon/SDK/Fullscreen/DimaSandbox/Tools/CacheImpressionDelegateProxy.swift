//
//  CacheImpressionDelegateProxy.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

final class CacheImpressionDelegateProxy: NSObject {
    private var cachedEntryID: String?
    private var cacheConfirmSent = false

    private let cache: BidCacheStore

    weak var delegate: FullscreenImpressionControllerDelegate?

    var onImpression: ArgumentClosure<String?>?
    var onHide: ArgumentClosure<String?>?
    var onFailToPresent: ArgumentClosure<String?>?

    var currentDemandID: String?

    init(cache: BidCacheStore) {
        self.cache = cache
    }
    
    func setCachedEntryId(_ id: String) {
        cachedEntryID = id
        cacheConfirmSent = false
    }

    func clearCachedEntryId() {
        cachedEntryID = nil
        cacheConfirmSent = false
    }
}

extension CacheImpressionDelegateProxy: FullscreenImpressionControllerDelegate {
    func willPresent(_ impression: inout any Impression) {
        delegate?.willPresent(&impression)

        if let id = cachedEntryID, !cacheConfirmSent {
            cache.confirm(entryID: id)
            cacheConfirmSent = true
            cachedEntryID = nil
        }
        onImpression?(currentDemandID)
    }
    
    func didFailToPresent(_ impression: inout (any Impression)?, error: SdkError) {
        delegate?.didFailToPresent(&impression, error: error)

        if let id = cachedEntryID, !cacheConfirmSent {
            cache.release(entryID: id)
            cachedEntryID = nil
        }
        onFailToPresent?(currentDemandID)
    }
    
    func didHide(_ impression: inout any Impression) {
        delegate?.didHide(&impression)

        if let id = cachedEntryID, !cacheConfirmSent {
            cache.release(entryID: id)
            cachedEntryID = nil
        }
        onHide?(currentDemandID)
        currentDemandID = nil
    }
    
    func didClick(_ impression: inout any Impression) {
        delegate?.didClick(&impression)
    }
    
    func didExpire(_ impression: inout any Impression) {
        delegate?.didExpire(&impression)

        if let id = cachedEntryID, !cacheConfirmSent {
            cache.release(entryID: id)
            cachedEntryID = nil
        }
    }
    
    func didReceiveReward(_ reward: any Reward, impression: inout any Impression) {
        delegate?.didReceiveReward(reward, impression: &impression)
    }
}
