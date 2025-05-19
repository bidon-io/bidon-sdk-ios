//
//  BannerAdInstance.m
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 22/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import "BannerAdInstance.h"

@implementation BannerAdInstance

- (instancetype)initWithEcpm:(double)ecpm
                    demandId:(nonnull NSString *)demandId
                  adInstance:(id<BDNAdView>)adInstance {
    self = [super init];
    if (self) {
        _ecpm = ecpm;
        _demandId = demandId;
        _adInstance = adInstance;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[BannerAdInstance alloc] initWithEcpm:self.ecpm
                                         demandId:self.demandId
                                       adInstance:self.adInstance];
}

@end
