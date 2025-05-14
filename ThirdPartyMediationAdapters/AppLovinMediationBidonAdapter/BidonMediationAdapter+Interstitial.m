//
//  BidonMediationAdapter+Interstitial.m
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 23/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import "BidonMediationAdapter+Interstitial.h"
#import "AdKeeperFactory.h"

@implementation BidonMediationAdapter (Interstitial)

- (void)loadInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters
                              andNotify:(id<MAInterstitialAdapterDelegate>)delegate {
    self.interstitialDelegate = delegate;
    [self updateBidonPrivacySettings:parameters];
    self.interstitialPlacementId = parameters.thirdPartyAdPlacementIdentifier;
    NSDictionary<NSString *, id> *customParams = parameters.customParameters;
    
    BOOL unicorn = [customParams[@"unicorn"] boolValue];
    
    id ecpmValue = customParams[@"ecpm"];
    double ecpm = [ecpmValue isKindOfClass:[NSNumber class]] ? [ecpmValue doubleValue] : 0.0;
    self.interstitialMaxEcpm = ecpm;
    double lastRegisteredEcpm = AdKeeperFactory.interstitial.lastEcpm;
    
    [AdKeeperFactory.interstitial registerEcpm:ecpm];
    
    if (unicorn) {
        NSLog(@"[BidonAdapter] Placement ID: %@, Unicorn Detected, ECPM: %f", self.interstitialPlacementId, ecpm);
        
        NSString *auctionKey = customParams[@"auction_key"];
        NSLog(@"[BidonAdapter] Loading interstitial ad for auction key: %@ and pricefloor: %d", auctionKey, 0);
        
        BDNInterstitial *interstitialAd = [[BDNInterstitial alloc] initWithAuctionKey:auctionKey];
        [interstitialAd setExtraValue:@"max" for:@"mediator"];
        if (lastRegisteredEcpm) {
            [interstitialAd setExtraValue:@(lastRegisteredEcpm) for:@"previous_auction_price"];
        }
        interstitialAd.delegate = self;
        
        self.interstitialAd = interstitialAd;
        [interstitialAd loadAdWith:0];
    } else {
        NSLog(@"[BidonAdapter] Placement ID: %@, No Unicorn Detected, ECPM: %f", self.interstitialPlacementId, ecpm);
        
        FullscreenAdInstance *cachedAd = [AdKeeperFactory.interstitial consumeAd:self.interstitialMaxEcpm];
        if (!cachedAd) {
            NSLog(@"[BidonAdapter] Interstitial ad failed to load: No fill, Placement ID: %@", self.interstitialPlacementId);
            [delegate didFailToLoadInterstitialAdWithError:[MAAdapterError errorWithCode:[MAAdapterError errorCodeNoFill]]];
            return;
        }
        
        NSLog(@"[BidonAdapter] Interstitial ad loaded from cache, Placement ID: %@", self.interstitialPlacementId);
        
        self.interstitialAd = (BDNInterstitial *)cachedAd.adInstance;
        self.interstitialAd.delegate = self;
        [delegate didLoadInterstitialAd];
    }
}

- (void)showInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters
                              andNotify:(id<MAInterstitialAdapterDelegate>)delegate {
    if (!self.interstitialAd || !self.interstitialAd.isReady) {
        NSLog(@"[BidonAdapter] Failed to present ad because it is nil or is not ready, Placement ID: %@", self.interstitialPlacementId);
        [delegate didFailToDisplayInterstitialAdWithError:[MAAdapterError errorWithAdapterError:MAAdapterError.adNotReady mediatedNetworkErrorCode:BDNErrorCodeAdNotReady mediatedNetworkErrorMessage:@"Ad is not ready"]];
        return;
    }
    
    if (!parameters.presentingViewController) {
        NSLog(@"[BidonAdapter] Failed to present ad because there is no presenting view controller, Placement ID: %@", self.interstitialPlacementId);
        [delegate didFailToDisplayInterstitialAdWithError:[MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError mediatedNetworkErrorCode:BDNErrorCodeUnspecified mediatedNetworkErrorMessage:@"Presenting view controller is nil"]];
        return;
    }
    
    NSLog(@"[BidonAdapter] Presenting ad, Placement ID: %@", self.interstitialPlacementId);
    [self.interstitialAd showAdFrom:parameters.presentingViewController];
}

- (void)handleInterstitialDidLoad:(id<BDNAdObject>)adObject ad:(id<BDNAd>)ad auctionInfo:(id<BDNAuctionInfo>)auctionInfo {
    if (self.interstitialAd) {
        double price = ad.price;
        
        NSLog(@"[BidonAdapter] Interstitial ad loaded, Placement ID: %@ ECPM: %f", self.interstitialPlacementId, price);
        FullscreenAdInstance *adInstance = [[FullscreenAdInstance alloc] initWithEcpm:price
                                                                             demandId:ad.adUnit.demandId
                                                                           adInstance:self.interstitialAd];
        
        if ([AdKeeperFactory.interstitial keepAd:adInstance]) {
            NSLog(@"[BidonAdapter] Interstitial ad kept in cache, Placement ID: %@", self.interstitialPlacementId);
        } else {
            NSLog(@"[BidonAdapter] Interstitial ad failed to keep in cache: cache is full, Placement ID: %@", self.interstitialPlacementId);
            [self onDestroyInterstitial];
        }
        
        // Consume the ad instance
        
        FullscreenAdInstance *cachedAd = [AdKeeperFactory.interstitial consumeAd:self.interstitialMaxEcpm];
        if (cachedAd) {
            NSLog(@"[BidonAdapter] Interstitial ad loaded from cache, Placement ID: %@", self.interstitialPlacementId);
            self.interstitialAd = (BDNInterstitial *)cachedAd.adInstance;
            self.interstitialAd.delegate = self;
            [self.interstitialDelegate didLoadInterstitialAd];
        } else {
            NSLog(@"[BidonAdapter] Interstitial ad failed to load from cache: No fill, Placement ID: %@", self.interstitialPlacementId);
            [self.interstitialDelegate didFailToLoadInterstitialAdWithError:[MAAdapterError errorWithCode:MAAdapterError.errorCodeNoFill]];
        }
    } else {
        NSLog(@"[BidonAdapter] Interstitial ad failed to load: Ad is null, Placement ID: %@", self.interstitialPlacementId);
        [self.interstitialDelegate didFailToLoadInterstitialAdWithError:[MAAdapterError errorWithCode:MAAdapterError.errorCodeNoFill]];
        [self onDestroyInterstitial];
    }
}

- (void)onDestroyInterstitial {
    self.interstitialAd = nil;
    self.interstitialDelegate = nil;
}

@end
