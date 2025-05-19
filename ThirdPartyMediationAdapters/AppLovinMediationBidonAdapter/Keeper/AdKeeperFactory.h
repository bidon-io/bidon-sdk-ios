//
//  AdKeeperFactory.h
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 22/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FullscreenAdKeeper.h"
#import "BannerAdKeeper.h"
#import <AppLovinSDK/AppLovinSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface AdKeeperFactory : NSObject

+ (FullscreenAdKeeper *)interstitial;
+ (FullscreenAdKeeper *)rewarded;
+ (BannerAdKeeper *)banner:(MAAdFormat *)format;

@end

NS_ASSUME_NONNULL_END
