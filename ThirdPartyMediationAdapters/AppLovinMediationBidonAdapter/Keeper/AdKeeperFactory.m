//
//  AdKeeperFactory.m
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 22/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import "AdKeeperFactory.h"

@implementation AdKeeperFactory

+ (FullscreenAdKeeper *)interstitial {
    static FullscreenAdKeeper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FullscreenAdKeeper alloc] init];
    });
    return sharedInstance;
}

+ (FullscreenAdKeeper *)rewarded {
    static FullscreenAdKeeper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FullscreenAdKeeper alloc] init];
    });
    return sharedInstance;
}

+ (BannerAdKeeper *)banner:(MAAdFormat *)format {
    static BannerAdKeeper *bannerInstance = nil;
    static BannerAdKeeper *leaderboardInstance = nil;
    static BannerAdKeeper *mrecInstance = nil;
    
    static dispatch_once_t bannerOnceToken;
    static dispatch_once_t leaderboardOnceToken;
    static dispatch_once_t mrecOnceToken;
    
    if (format == MAAdFormat.banner) {
        dispatch_once(&bannerOnceToken, ^{
            bannerInstance = [[BannerAdKeeper alloc] init];
        });
        return bannerInstance;
    } else if (format == MAAdFormat.leader) {
        dispatch_once(&leaderboardOnceToken, ^{
            leaderboardInstance = [[BannerAdKeeper alloc] init];
        });
        return leaderboardInstance;
    } else if (format == MAAdFormat.mrec) {
        dispatch_once(&mrecOnceToken, ^{
            mrecInstance = [[BannerAdKeeper alloc] init];
        });
        return mrecInstance;
    } else {
        dispatch_once(&bannerOnceToken, ^{
            bannerInstance = [[BannerAdKeeper alloc] init];
        });
        return bannerInstance;
    }
}

@end
