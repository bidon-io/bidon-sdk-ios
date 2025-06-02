//
//  BidonMediationAdapter.h
//  Sandbox
//
//  Created by Евгения Григорович on 20/03/2025.
//  Copyright © 2025 Stack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <Bidon/Bidon.h>

NS_ASSUME_NONNULL_BEGIN

@interface BidonMediationAdapter : ALMediationAdapter <MAInterstitialAdapter, MAAdViewAdapter, MARewardedAdapter, BDNAdViewDelegate, BDNFullscreenAdDelegate, BDNRewardedAdDelegate>

@property (nonatomic, strong, nullable) BDNBannerView *banner;
@property (nonatomic, weak, nullable) id<MAAdViewAdapterDelegate> bannerDelegate;
@property (nonatomic, copy) NSString *bannerPlacementId;
@property (nonatomic, assign) double bannerMaxEcpm;
@property (nonatomic, strong) MAAdFormat *adFormat;

@property (nonatomic, strong, nullable) BDNInterstitial *interstitialAd;
@property (nonatomic, weak, nullable) id<MAInterstitialAdapterDelegate> interstitialDelegate;
@property (nonatomic, copy) NSString *interstitialPlacementId;
@property (nonatomic, assign) double interstitialMaxEcpm;

@property (nonatomic, strong, nullable) BDNRewardedAd *rewardedAd;
@property (nonatomic, weak, nullable) id<MARewardedAdapterDelegate> rewardedDelegate;
@property (nonatomic, copy) NSString *rewardedPlacementId;
@property (nonatomic, assign) double rewardedMaxEcpm;

- (void)updateBidonPrivacySettings:(id<MAAdapterParameters>)parameters;

@end

NS_ASSUME_NONNULL_END
