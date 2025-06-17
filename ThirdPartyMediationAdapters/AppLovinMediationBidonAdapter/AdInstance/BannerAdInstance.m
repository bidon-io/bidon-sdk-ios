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
                          ad:(id<BDNAd>)ad
                  adInstance:(id<BDNAdView>)adInstance {
    self = [super init];
    if (self) {
        _ecpm = ecpm;
        _demandId = demandId;
        _adInstance = adInstance;
        _ad = ad;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[BannerAdInstance alloc] initWithEcpm:self.ecpm
                                         demandId:self.demandId
                                               ad:self.ad
                                       adInstance:self.adInstance];
}

@end
