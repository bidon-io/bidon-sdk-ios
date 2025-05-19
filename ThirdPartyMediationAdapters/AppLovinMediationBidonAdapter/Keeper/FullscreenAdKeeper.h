//
//  FullscreenAdKeeper.h
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 21/03/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FullscreenAdInstance.h"

NS_ASSUME_NONNULL_BEGIN

@interface FullscreenAdKeeper : NSObject

@property (nonatomic, assign) double lastEcpm;

- (void)registerEcpm:(double)ecpm;
- (BOOL)keepAd:(FullscreenAdInstance *)ad;
- (nullable FullscreenAdInstance *)consumeAd:(double)ecpm;
@end

NS_ASSUME_NONNULL_END
