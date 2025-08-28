//
//  BidonMediationAdapter+Rewarded.m
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 23/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import "BidonMediationAdapter+Rewarded.h"
#import "AdKeeperFactory.h"

@implementation BidonMediationAdapter (Rewarded)

- (void)loadRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters
                          andNotify:(id<MARewardedAdapterDelegate>)delegate {
    self.rewardedAdUnitId = parameters.adUnitIdentifier;
    self.rewardedDelegate = delegate;
    [self updateBidonPrivacySettings:parameters];
    self.rewardedPlacementId = parameters.thirdPartyAdPlacementIdentifier;
    NSDictionary<NSString *, id> *customParams = parameters.customParameters;
    
    BOOL shouldLoad = [customParams[@"should_load"] ?: customParams[@"unicorn"] boolValue];
    
    id ecpmValue = customParams[@"ecpm"];
    double ecpm = [ecpmValue isKindOfClass:[NSNumber class]] ? [ecpmValue doubleValue] : 0.0;
    self.rewardedMaxEcpm = ecpm;
    double lastRegisteredEcpm = [AdKeeperFactory rewarded:self.rewardedAdUnitId].lastEcpm;
    
    [[AdKeeperFactory rewarded:self.rewardedAdUnitId] registerEcpm:ecpm];
    
    if (shouldLoad) {
        NSLog(@"[BidonAdapter] [%@] Placement ID: %@, Unicorn Detected, ECPM: %f", self.rewardedAdUnitId, self.rewardedPlacementId, ecpm);
        
        NSString *auctionKey = customParams[@"auction_key"];
        NSLog(@"[BidonAdapter] [%@] Loading rewarded ad for auction key: %@ and pricefloor: %d", self.rewardedAdUnitId, auctionKey, 0);
        
        BDNRewardedAd *rewardedAd = [[BDNRewardedAd alloc] initWithAuctionKey:auctionKey];
        [rewardedAd setExtraValue:@"max" for:@"mediator"];

        if (lastRegisteredEcpm) {
            [rewardedAd setExtraValue:@(lastRegisteredEcpm) for:@"previous_auction_price"];
        }
        rewardedAd.delegate = self;
        
        self.rewardedAd = rewardedAd;
        [rewardedAd loadAdWith:0];
    } else {
        NSLog(@"[BidonAdapter] [%@] Placement ID: %@, No Unicorn Detected, ECPM: %f", self.rewardedAdUnitId, self.rewardedPlacementId, ecpm);
        
        FullscreenAdInstance *cachedAd = [[AdKeeperFactory rewarded:self.rewardedAdUnitId] consumeAd:self.rewardedMaxEcpm];
        if (!cachedAd) {
            NSLog(@"[BidonAdapter] [%@] Rewarded ad failed to load: No fill, Placement ID: %@", self.rewardedAdUnitId, self.rewardedPlacementId);
            [delegate didFailToLoadRewardedAdWithError:[MAAdapterError errorWithCode:[MAAdapterError errorCodeTimeout]]];
            return;
        }
        
        NSLog(@"[BidonAdapter] [%@] Rewarded ad loaded from cache, Placement ID: %@", self.rewardedAdUnitId, self.rewardedPlacementId);
        
        self.rewardedAd = (BDNRewardedAd *)cachedAd.adInstance;
        self.rewardedAd.delegate = self;
        [delegate didLoadRewardedAdWithExtraInfo:[self extrasDictForEcpm:ecpm ad:cachedAd.ad]];
    }
}

- (void)showRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters
                          andNotify:(id<MARewardedAdapterDelegate>)delegate {
    if (!self.rewardedAd || !self.rewardedAd.isReady) {
        NSLog(@"[BidonAdapter] [%@] Failed to present ad because it is nil or is not ready, Placement ID: %@", self.rewardedAdUnitId, self.rewardedPlacementId);
        [delegate didFailToDisplayRewardedAdWithError:[MAAdapterError errorWithAdapterError:MAAdapterError.adNotReady mediatedNetworkErrorCode:BDNErrorCodeAdNotReady mediatedNetworkErrorMessage:@"Ad is not ready"]];
        return;
    }
    
    if (!parameters.presentingViewController) {
        NSLog(@"[BidonAdapter] [%@] Failed to present ad because there is no presenting view controller, Placement ID: %@", self.rewardedAdUnitId, self.rewardedPlacementId);
        [delegate didFailToDisplayRewardedAdWithError:[MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError mediatedNetworkErrorCode:BDNErrorCodeUnspecified mediatedNetworkErrorMessage:@"Presenting view controller is nil"]];
        return;
    }
    
    NSLog(@"[BidonAdapter] [%@] Presenting ad, Placement ID: %@", self.rewardedAdUnitId, self.rewardedPlacementId);
    [self.rewardedAd showAdFrom:parameters.presentingViewController];
}

- (void)handleRewardedDidLoad:(id<BDNAdObject>)adObject ad:(id<BDNAd>)ad auctionInfo:(id<BDNAuctionInfo>)auctionInfo {
    if (self.rewardedAd) {
        double price = ad.price;
        
        NSLog(@"[BidonAdapter] [%@] Rewarded ad loaded, Placement ID: %@ ECPM: %f", self.rewardedAdUnitId, self.rewardedPlacementId, price);
        
        FullscreenAdInstance *adInstance = [[FullscreenAdInstance alloc] initWithEcpm:price
                                                                             demandId:ad.adUnit.demandId
                                                                                   ad:ad
                                                                           adInstance:self.rewardedAd];
        
        if ([[AdKeeperFactory rewarded:self.rewardedAdUnitId] keepAd:adInstance]) {
            NSLog(@"[BidonAdapter] [%@] Rewarded ad kept in cache, Placement ID: %@", self.rewardedAdUnitId, self.rewardedPlacementId);
        } else {
            NSLog(@"[BidonAdapter] [%@] Rewarded ad failed to keep in cache: cache is full, Placement ID: %@", self.rewardedAdUnitId, self.rewardedPlacementId);
            [self onDestroyRewarded];
        }
        
        // Consume the ad instance
        FullscreenAdInstance *cachedAd = [[AdKeeperFactory rewarded:self.rewardedAdUnitId] consumeAd:self.rewardedMaxEcpm];
        if (cachedAd) {
            NSLog(@"[BidonAdapter] [%@] Rewarded ad loaded from cache, Placement ID: %@", self.rewardedAdUnitId, self.rewardedPlacementId);
            self.rewardedAd = (BDNRewardedAd *)cachedAd.adInstance;
            self.rewardedAd.delegate = self;
            [self.rewardedDelegate didLoadRewardedAdWithExtraInfo:[self extrasDictForEcpm:self.rewardedMaxEcpm ad:cachedAd.ad]];
        } else {
            NSLog(@"[BidonAdapter] [%@] Rewarded ad failed to load from cache: No fill, Placement ID: %@", self.rewardedAdUnitId, self.rewardedPlacementId);
            [self.rewardedDelegate didFailToLoadRewardedAdWithError:[MAAdapterError errorWithCode:MAAdapterError.errorCodeNoFill]];
        }
    } else {
        NSLog(@"[BidonAdapter] [%@] Rewarded ad failed to load: Ad is null, Placement ID: %@", self.rewardedAdUnitId, self.rewardedPlacementId);
        [self.rewardedDelegate didFailToLoadRewardedAdWithError:[MAAdapterError errorWithCode:MAAdapterError.errorCodeNoFill]];
        [self onDestroyRewarded];
    }
}

- (void)onDestroyRewarded {
    self.rewardedAd = nil;
    self.rewardedDelegate = nil;
}

@end
