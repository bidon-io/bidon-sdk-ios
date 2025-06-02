//
//  BidonMediationAdapter+Rewarded.h
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

@interface BidonMediationAdapter (Rewarded)

- (void)handleRewardedDidLoad:(id<BDNAdObject>)adObject ad:(id<BDNAd>)ad auctionInfo:(id<BDNAuctionInfo>)auctionInfo;
- (void)onDestroyRewarded;

@end

NS_ASSUME_NONNULL_END
