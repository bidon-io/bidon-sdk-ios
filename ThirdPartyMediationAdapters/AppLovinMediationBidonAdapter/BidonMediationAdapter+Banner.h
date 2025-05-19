//
//  BidonMediationAdapter+Banner.h
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 22/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BidonMediationAdapter.h"
#import <AppLovinSDK/AppLovinSDK.h>
#import <Bidon/Bidon.h>

NS_ASSUME_NONNULL_BEGIN

@interface BidonMediationAdapter (Banner)

- (void)handleBannerDidLoad:(id<BDNAdObject>)adObject ad:(id<BDNAd>)ad auctionInfo:(id<BDNAuctionInfo>)auctionInfo;
- (void)onDestroyBanner;
    
@end

NS_ASSUME_NONNULL_END
