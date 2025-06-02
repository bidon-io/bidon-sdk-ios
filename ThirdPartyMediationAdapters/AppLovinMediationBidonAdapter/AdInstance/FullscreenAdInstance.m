//
//  FullscreenAdInstance.m
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 21/03/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import "FullscreenAdInstance.h"

@implementation FullscreenAdInstance

- (instancetype)initWithEcpm:(double)ecpm
                    demandId:(nonnull NSString *)demandId
                  adInstance:(id<BDNFullscreenAd>)adInstance {
    self = [super init];
    if (self) {
        _ecpm = ecpm;
        _demandId = demandId;
        _adInstance = adInstance;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[FullscreenAdInstance alloc] initWithEcpm:self.ecpm
                                             demandId:self.demandId
                                           adInstance:self.adInstance];
}

@end
