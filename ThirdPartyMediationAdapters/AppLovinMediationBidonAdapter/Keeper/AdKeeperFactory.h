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

+ (FullscreenAdKeeper *)interstitial:(NSString *)key;
+ (FullscreenAdKeeper *)rewarded:(NSString *)key;
+ (BannerAdKeeper *)banner:(MAAdFormat *)format key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
