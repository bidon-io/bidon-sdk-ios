//
//  BidonMediationAdapter+Interstitial.h
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 23/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BidonMediationAdapter.h"
#import <AppLovinSDK/AppLovinSDK.h>
#import <Bidon/Bidon.h>

NS_ASSUME_NONNULL_BEGIN

@interface BidonMediationAdapter (Interstitial)

- (void)handleInterstitialDidLoad:(id<BDNAdObject>)adObject ad:(id<BDNAd>)ad auctionInfo:(id<BDNAuctionInfo>)auctionInfo;
- (void)onDestroyInterstitial;

@end

NS_ASSUME_NONNULL_END
