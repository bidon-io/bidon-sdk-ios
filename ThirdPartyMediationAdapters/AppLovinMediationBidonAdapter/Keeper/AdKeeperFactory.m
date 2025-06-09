//
//  AdKeeperFactory.m
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 22/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import "AdKeeperFactory.h"

@implementation AdKeeperFactory

+ (BOOL)isSingleKeeperEnabled {
    NSString *value = ALSdk.shared.settings.extraParameters[@"single_keeper_enabled"];
    return [value boolValue];
}

+ (FullscreenAdKeeper *)interstitial:(NSString *)key {
    static NSMutableDictionary<NSString *, FullscreenAdKeeper *> *interstitialKeepers;
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    static FullscreenAdKeeper *singletonKeeper = nil;

    dispatch_once(&onceToken, ^{
        interstitialKeepers = [NSMutableDictionary dictionary];
        queue = dispatch_queue_create("io.bidon.bcamax.interstitial.queue", DISPATCH_QUEUE_CONCURRENT);
        singletonKeeper = [[FullscreenAdKeeper alloc] initWithAdUnitId:@"singleton_interstitial"];
    });

    if ([self isSingleKeeperEnabled]) {
        return singletonKeeper;
    }

    __block FullscreenAdKeeper *keeper;
    dispatch_sync(queue, ^{
        keeper = interstitialKeepers[key];
    });

    if (!keeper) {
        dispatch_barrier_sync(queue, ^{
            if (!interstitialKeepers[key]) {
                interstitialKeepers[key] = [[FullscreenAdKeeper alloc] initWithAdUnitId:key];
            }
            keeper = interstitialKeepers[key];
        });
    }

    return keeper;
}

+ (FullscreenAdKeeper *)rewarded:(NSString *)key {
    static NSMutableDictionary<NSString *, FullscreenAdKeeper *> *rewardedKeepers;
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    static FullscreenAdKeeper *singletonKeeper = nil;

    dispatch_once(&onceToken, ^{
        rewardedKeepers = [NSMutableDictionary dictionary];
        queue = dispatch_queue_create("io.bidon.bcamax.rewarded.queue", DISPATCH_QUEUE_CONCURRENT);
        singletonKeeper = [[FullscreenAdKeeper alloc] initWithAdUnitId:@"singleton_rewarded"];
    });

    if ([self isSingleKeeperEnabled]) {
        return singletonKeeper;
    }

    __block FullscreenAdKeeper *keeper;
    dispatch_sync(queue, ^{
        keeper = rewardedKeepers[key];
    });

    if (!keeper) {
        dispatch_barrier_sync(queue, ^{
            if (!rewardedKeepers[key]) {
                rewardedKeepers[key] = [[FullscreenAdKeeper alloc] initWithAdUnitId:key];
            }
            keeper = rewardedKeepers[key];
        });
    }

    return keeper;
}

+ (BannerAdKeeper *)banner:(MAAdFormat *)format key:(NSString *)key {
    static NSMutableDictionary<NSString *, BannerAdKeeper *> *bannerKeepers;
    static NSMutableDictionary<NSString *, BannerAdKeeper *> *singletonBannerKeepers;
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        bannerKeepers = [NSMutableDictionary dictionary];
        singletonBannerKeepers = [NSMutableDictionary dictionary];
        queue = dispatch_queue_create("io.bidon.bcamax.banner.queue", DISPATCH_QUEUE_CONCURRENT);
    });

    NSString *formatLabel = format.label;

    if ([self isSingleKeeperEnabled]) {
        __block BannerAdKeeper *singletonKeeper;
        dispatch_sync(queue, ^{
            singletonKeeper = singletonBannerKeepers[formatLabel];
        });

        if (!singletonKeeper) {
            dispatch_barrier_sync(queue, ^{
                if (!singletonBannerKeepers[formatLabel]) {
                    singletonBannerKeepers[formatLabel] = [[BannerAdKeeper alloc] initWithAdUnitId:[NSString stringWithFormat:@"singleton_banner_%@", formatLabel]];
                }
                singletonKeeper = singletonBannerKeepers[formatLabel];
            });
        }

        return singletonKeeper;
    }

    NSString *combinedKey = [NSString stringWithFormat:@"%@_%@", formatLabel, key];

    __block BannerAdKeeper *keeper;
    dispatch_sync(queue, ^{
        keeper = bannerKeepers[combinedKey];
    });

    if (!keeper) {
        dispatch_barrier_sync(queue, ^{
            if (!bannerKeepers[combinedKey]) {
                bannerKeepers[combinedKey] = [[BannerAdKeeper alloc] initWithAdUnitId:key];
            }
            keeper = bannerKeepers[combinedKey];
        });
    }

    return keeper;
}


@end
