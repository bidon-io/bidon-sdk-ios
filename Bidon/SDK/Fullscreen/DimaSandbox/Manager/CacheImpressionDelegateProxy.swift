//
//  CacheImpressionDelegateProxy.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

final class CacheImpressionDelegateProxy: NSObject {
    private var cachedEntryId: String?
    private var cacheConfirmSent = false

    private let cache: BidCache

    weak var delegate: FullscreenImpressionControllerDelegate?

    var onImpression: ((_ demandId: String?) -> Void)?
    var onHide: ((_ demandId: String?) -> Void)?
    var onFailToPresent: ((_ demandId: String?) -> Void)?

    var currentDemandId: String?

    init(cache: BidCache) {
        self.cache = cache
    }
    
    func setCachedEntryId(_ id: String) {
        cachedEntryId = id
        cacheConfirmSent = false
    }

    func clearCachedEntryId() {
        cachedEntryId = nil
        cacheConfirmSent = false
    }
}

extension CacheImpressionDelegateProxy: FullscreenImpressionControllerDelegate {
    func willPresent(_ impression: inout any Impression) {
        delegate?.willPresent(&impression)

        if let id = cachedEntryId, !cacheConfirmSent {
            cache.confirm(entryId: id)
            cacheConfirmSent = true
            cachedEntryId = nil
        }
        onImpression?(currentDemandId)
    }
    
    func didFailToPresent(_ impression: inout (any Impression)?, error: SdkError) {
        delegate?.didFailToPresent(&impression, error: error)

        if let id = cachedEntryId, !cacheConfirmSent {
            cache.release(entryId: id)
            cachedEntryId = nil
        }
        onFailToPresent?(currentDemandId)
    }
    
    func didHide(_ impression: inout any Impression) {
        delegate?.didHide(&impression)

        if let id = cachedEntryId, !cacheConfirmSent {
            cache.release(entryId: id)
            cachedEntryId = nil
        }
        onHide?(currentDemandId)
        currentDemandId = nil
    }
    
    func didClick(_ impression: inout any Impression) {
        delegate?.didClick(&impression)
    }
    
    func didExpire(_ impression: inout any Impression) {
        delegate?.didExpire(&impression)

        if let id = cachedEntryId, !cacheConfirmSent {
            cache.release(entryId: id)
            cachedEntryId = nil
        }
    }
    
    func didReceiveReward(_ reward: any Reward, impression: inout any Impression) {
        delegate?.didReceiveReward(reward, impression: &impression)
    }
}
