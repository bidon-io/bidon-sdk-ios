//
//  BidonMediationAdapter+Banner.m
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 22/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import "BidonMediationAdapter+Banner.h"
#import "AdKeeperFactory.h"

@implementation BidonMediationAdapter (Banner)

- (void)loadAdViewAdForParameters:(id<MAAdapterResponseParameters>)parameters adFormat:(MAAdFormat *)adFormat andNotify:(id<MAAdViewAdapterDelegate>)delegate {
    self.bannerDelegate = delegate;
    self.adFormat = adFormat;
    [self updateBidonPrivacySettings:parameters];
    self.bannerPlacementId = parameters.thirdPartyAdPlacementIdentifier;
    NSDictionary<NSString *, id> *customParams = parameters.customParameters;

    BOOL unicorn = [customParams[@"unicorn"] boolValue];
    
    id ecpmValue = customParams[@"ecpm"];
    double ecpm = [ecpmValue isKindOfClass:[NSNumber class]] ? [ecpmValue doubleValue] : 0.0;
    self.bannerMaxEcpm = ecpm;
    double lastRegisteredEcpm = [AdKeeperFactory banner:adFormat].lastEcpm;

    [[AdKeeperFactory banner:adFormat] registerEcpm:ecpm];
    
    if (unicorn) {
        NSLog(@"[BidonAdapter] Placement ID: %@, Unicorn Detected, ECPM: %f", self.bannerPlacementId, ecpm);

        NSString *auctionKey = customParams[@"auction_key"];
        NSLog(@"[BidonAdapter] Loading banner ad for auction key: %@ and pricefloor: %d", auctionKey, 0);

        BDNBannerView *banner = [[BDNBannerView alloc] initWithFrame:CGRectZero auctionKey:auctionKey];
        [banner setExtraValue:@"max" for:@"mediator"];
        if (lastRegisteredEcpm) {
            [banner setExtraValue:@(lastRegisteredEcpm) for:@"previous_auction_price"];
        }
        banner.delegate = self;
        
        self.banner = banner;
        [banner loadAdWith:0 auctionKey:auctionKey];
    } else {
        NSLog(@"[BidonAdapter] Placement ID: %@, No Unicorn Detected, ECPM: %f", self.bannerPlacementId, ecpm);
        
        BannerAdInstance *cachedAd = [[AdKeeperFactory banner:adFormat] consumeAd:self.bannerMaxEcpm];
        if (!cachedAd) {
            NSLog(@"[BidonAdapter] Banner ad failed to load: No fill, Placement ID: %@", self.bannerPlacementId);
            [delegate didFailToLoadAdViewAdWithError:[MAAdapterError errorWithCode:[MAAdapterError errorCodeTimeout]]];
            return;
        }
        
        NSLog(@"[BidonAdapter] Banner ad loaded from cache, Placement ID: %@", self.bannerPlacementId);
        
        self.banner = (BDNBannerView *)cachedAd.adInstance;
        self.banner.delegate = self;
        [delegate didLoadAdForAdView:self.banner];
    }
}

- (void)handleBannerDidLoad:(id<BDNAdObject>)adObject ad:(id<BDNAd>)ad auctionInfo:(id<BDNAuctionInfo>)auctionInfo {
    if (self.banner) {
        double price = ad.price;
        
        NSLog(@"[BidonAdapter] Banner ad loaded, Placement ID: %@ ECPM: %f", self.bannerPlacementId, price);
        
        BannerAdInstance *adInstance = [[BannerAdInstance alloc] initWithEcpm:price
                                                                     demandId:ad.adUnit.demandId
                                                                   adInstance:self.banner];
        
        if ([[AdKeeperFactory banner:self.adFormat] keepAd:adInstance]) {
            NSLog(@"[BidonAdapter] Banner ad kept in cache, Placement ID: %@", self.bannerPlacementId);
        } else {
            NSLog(@"[BidonAdapter] Banner ad failed to keep in cache: cache is full, Placement ID: %@", self.bannerPlacementId);
            [self onDestroyBanner];
        }
        
        // Consume the ad instance
        
        BannerAdInstance *cachedAd = [[AdKeeperFactory banner:self.adFormat] consumeAd:self.bannerMaxEcpm];
        if (cachedAd) {
            NSLog(@"[BidonAdapter] Banner ad loaded from cache, Placement ID: %@", self.bannerPlacementId);
            self.banner = (BDNBannerView *)cachedAd.adInstance;
            self.banner.delegate = self;
            [self.bannerDelegate didLoadAdForAdView:self.banner];
        } else {
            NSLog(@"[BidonAdapter] Banner ad failed to load from cache: No fill, Placement ID: %@", self.bannerPlacementId);
            [self.bannerDelegate didFailToLoadAdViewAdWithError:[MAAdapterError errorWithCode:MAAdapterError.errorCodeNoFill]];
        }
    } else {
        NSLog(@"[BidonAdapter] Banner ad failed to load: Ad is null, Placement ID: %@", self.bannerPlacementId);
        [self.bannerDelegate didFailToLoadAdViewAdWithError:[MAAdapterError errorWithCode:MAAdapterError.errorCodeNoFill]];
        [self onDestroyBanner];
    }
}

- (void)adView:(UIView <BDNAdView> * _Nonnull)adView willPresentScreen:(id <BDNAd> _Nonnull)ad {
    
}

- (void)adView:(UIView <BDNAdView> * _Nonnull)adView didDismissScreen:(id <BDNAd> _Nonnull)ad {
    
}

- (void)adView:(UIView <BDNAdView> * _Nonnull)adView willLeaveApplication:(id <BDNAd> _Nonnull)ad {
    
}

- (void)onDestroyBanner {
    self.banner = nil;
    self.bannerDelegate = nil;
}

@end
