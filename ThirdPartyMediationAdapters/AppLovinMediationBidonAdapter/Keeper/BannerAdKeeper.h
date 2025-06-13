//
//  BannerAdKeeper.h
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 22/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BannerAdInstance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BannerAdKeeper : NSObject

@property (nonatomic, assign) double lastEcpm;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId;

- (void)registerEcpm:(double)ecpm;
- (BOOL)keepAd:(BannerAdInstance *)ad;
- (nullable BannerAdInstance *)consumeAd:(double)ecpm;

@end

NS_ASSUME_NONNULL_END
