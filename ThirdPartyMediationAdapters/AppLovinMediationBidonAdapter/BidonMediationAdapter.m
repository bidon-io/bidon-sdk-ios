//
//  BidonMediationAdapter.m
//  APDAppLovinMAXAdapter
//
//  Created by Евгения Григорович on 20/03/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import "BidonMediationAdapter.h"
#import <AppLovinSDK/AppLovinSDK.h>
#import <Bidon/Bidon-Swift.h>
#import "AdKeeperFactory.h"
#import "FullscreenAdInstance.h"
#import "BidonMediationAdapter+Banner.h"
#import "BidonMediationAdapter+Interstitial.h"
#import "BidonMediationAdapter+Rewarded.h"

@implementation BidonMediationAdapter

- (NSString *)sdkVersion {
    return [BDNSdk sdkVersion];
}

- (NSString *)adapterVersion {
    return [NSString stringWithFormat:@"%@.0.0", [BDNSdk sdkVersion]];
}

- (void)destroy {
    // No implementation needed
}

- (void)initializeWithParameters:(id<MAAdapterInitializationParameters>)parameters
               completionHandler:(void (^)(MAAdapterInitializationStatus, NSString * _Nullable))completionHandler {
    [self updateBidonPrivacySettings:parameters];
    NSString *appKey = parameters.serverParameters[@"app_id"];
    
    if ([BDNSdk isInitialized]) {
        completionHandler(MAAdapterInitializationStatusInitializedSuccess, @"");
    } else if (appKey.length == 0) {
        completionHandler(MAAdapterInitializationStatusInitializedFailure, @"Missing app key");
    } else {
        BDNSdk.baseURL = @"https://b.appbaqend.com";
        BDNSdk.isTestMode = parameters.isTesting;
        [BDNSdk setLogLevel:BDNLoggerLevelVerbose];
        [BDNSdk registerDefaultAdapters];
        
        [BDNSdk initializeWithAppKey:appKey completion:^{
            completionHandler(MAAdapterInitializationStatusInitializedSuccess, @"");
        }];
    }
}


- (void)updateBidonPrivacySettings:(id<MAAdapterParameters>)parameters {
    BDNSdk.regulations.gdprConsentString = parameters.consentString;
    
    NSString *usPrivacyString = nil;
    if ([parameters.isDoNotSell  isEqual: @(1)]) {
        usPrivacyString = @"1YY-";
    } else if (parameters.isDoNotSell == NO) {
        usPrivacyString = @"1YN-";
    } else {
        usPrivacyString = @"1---";
    }
    BDNSdk.regulations.usPrivacyString = usPrivacyString;
}

- (NSDictionary<NSString *, id> *)extrasDictForEcpm:(double)ecpm ad:(id<BDNAd>)ad {
    NSMutableDictionary<NSString *, id> *extras = [NSMutableDictionary dictionary];
    extras[@"max_ecpm"] = @(ecpm);
    switch (ad.adType) {
        case AdTypeBanner:
            extras[@"max_placement"] = self.bannerPlacementId ?: @"";
            break;
        case AdTypeInterstitial:
            extras[@"max_placement"] = self.interstitialPlacementId ?: @"";
            break;
        case AdTypeRewarded:
            extras[@"max_placement"] = self.rewardedPlacementId ?: @"";
            break;
    }
    extras[@"ad_unit_uid"] = ad.adUnit.uid ?: @"";
    extras[@"demand_id"] = ad.adUnit.demandId ?: @"";
    extras[@"price"] = @(ad.price ?: ad.adUnit.pricefloor) ?: @"";
    extras[@"bid_type"] = ad.adUnit.bidType == 1 ? @"CPM" : @"RTB";
    
    NSMutableDictionary<NSString *, id> *adValues = [NSMutableDictionary dictionary];
    adValues[@"ad_values"] = extras;
        
    return adValues;
}

#pragma mark - FullscreenAdDelegate

- (void)fullscreenAd:(id<BDNFullscreenAd>)fullscreenAd didDismissAd:(id<BDNAd>)ad {
    if (ad.adType == 0) { // banner
        [self.bannerDelegate didHideAdViewAd];
        [self onDestroyBanner];
    } else if (ad.adType == 1) { // interstitial
        [self.interstitialDelegate didHideInterstitialAd];
        [self onDestroyInterstitial];
    } else if (ad.adType == 2) { // rewarded
        [self.rewardedDelegate didHideRewardedAd];
        [self onDestroyRewarded];
    } else {
        NSAssert(YES, @"Invalid ad type");
    }
}

- (void)fullscreenAd:(id<BDNFullscreenAd>)fullscreenAd willPresentAd:(id<BDNAd>)ad {
    if (ad.adType == 1) { // interstitial
        [self.interstitialDelegate didDisplayInterstitialAd];
    } else if (ad.adType == 2) { // rewarded
        [self.rewardedDelegate didDisplayRewardedAd];
    } else {
        NSAssert(YES, @"Invalid ad type");
    }
}

- (void)adObject:(id<BDNAdObject>)adObject didRecordClick:(id<BDNAd>)ad {
    if (ad.adType == 0) { // banner
        [self.bannerDelegate didClickAdViewAd];
    } else if (ad.adType == 1) { // interstitial
        [self.interstitialDelegate didClickInterstitialAd];
    } else if (ad.adType == 2) { // rewarded
        [self.rewardedDelegate didClickRewardedAd];
    } else {
        NSAssert(YES, @"Invalid ad type");
    }
}

- (void)adObject:(id<BDNAdObject>)adObject didLoadAd:(id<BDNAd>)ad auctionInfo:(id<BDNAuctionInfo>)auctionInfo {
    if (ad.adType == 0) { // banner
        [self handleBannerDidLoad:adObject ad:ad auctionInfo:auctionInfo];
    } else if (ad.adType == 1) { // interstitial
        [self handleInterstitialDidLoad:adObject ad:ad auctionInfo:auctionInfo];
    } else if (ad.adType == 2) { // rewarded
        [self handleRewardedDidLoad:adObject ad:ad auctionInfo:auctionInfo];
    } else {
        NSAssert(YES, @"Invalid ad type");
    }
}

- (void)adObject:(id<BDNAdObject>)adObject didFailToLoadAd:(NSError *)error auctionInfo:(id<BDNAuctionInfo>)auctionInfo {
    if (adObject == self.banner) {
        NSLog(@"[BidonAdapter] Banner ad failed to load: No fill");
        [self.bannerDelegate didFailToLoadAdViewAdWithError:[MAAdapterError errorWithAdapterError:MAAdapterError.noFill mediatedNetworkErrorCode:BDNErrorCodeNoFill mediatedNetworkErrorMessage:error.localizedDescription]];
        [self onDestroyBanner];
    } else if (adObject == self.interstitialAd) {
        [self handleInterstitialFailedToLoad];
        [self.interstitialDelegate didFailToLoadInterstitialAdWithError:[MAAdapterError errorWithAdapterError:MAAdapterError.noFill mediatedNetworkErrorCode:BDNErrorCodeNoFill mediatedNetworkErrorMessage:error.localizedDescription]];
        [self onDestroyInterstitial];
    } else if (adObject == self.rewardedAd) {
        NSLog(@"[BidonAdapter] Rewarded ad failed to load: No fill");
        [self.rewardedDelegate didFailToLoadRewardedAdWithError:[MAAdapterError errorWithAdapterError:MAAdapterError.noFill mediatedNetworkErrorCode:BDNErrorCodeNoFill mediatedNetworkErrorMessage:error.localizedDescription]];
        [self onDestroyRewarded];
    } else {
        NSAssert(YES, @"Invalid ad type");
    }
}

- (void)adObject:(id<BDNAdObject>)adObject didRecordImpression:(id<BDNAd>)ad {
    if (ad.adType == 0) {
        [self.bannerDelegate didDisplayAdViewAd];
    }
}

- (void)rewardedAd:(id<BDNRewardedAd>)rewardedAd didRewardUser:(id<BDNReward>)reward ad:(id<BDNAd>)ad {
    [self.rewardedDelegate didRewardUserWithReward:[MAReward rewardWithAmount:reward.amount label:reward.label]];
}

@end
