//
//  BannerAdKeeper.m
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 22/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import "BannerAdKeeper.h"

@interface BannerAdKeeper ()

@property (nonatomic, strong) NSMutableArray<NSNumber *> *registeredEcpm;
@property (nonatomic, strong, nullable) BannerAdInstance *bannerAdInstance;

@end

@implementation BannerAdKeeper

- (instancetype)init {
    self = [super init];
    if (self) {
        _registeredEcpm = [NSMutableArray new];
    }
    return self;
}

- (void)registerEcpm:(double)ecpm {
    NSLog(@"[BidonAdapter] Registering eCPM: %f", ecpm);
    if (![self.registeredEcpm containsObject:@(ecpm)]) {
        [self.registeredEcpm addObject:@(ecpm)];
    }
    self.lastEcpm = ecpm;
    NSMutableString *values = [NSMutableString new];
    for (int i = 0; i < self.registeredEcpm.count; i++) {
        [values appendFormat:@"%@, ", self.registeredEcpm[i]];
    }
    NSLog(@"[BidonAdapter] Current registered eCPM values: %@", values);
}

- (BOOL)keepAd:(BannerAdInstance *)ad {
    if (!self.bannerAdInstance || self.bannerAdInstance.ecpm < ad.ecpm) {
        NSLog(@"[BidonAdapter] Keeping new ad instance with eCPM: %f (previous: %@)",
              ad.ecpm,
              self.bannerAdInstance ? @(self.bannerAdInstance.ecpm) : @"none");
        
        NSString *markedDemandId = [NSString stringWithFormat:@"maxca_%@", self.bannerAdInstance.demandId];
        [self.bannerAdInstance.adInstance notifyLossWithExternalDemandId:markedDemandId price:ad.ecpm];

        self.bannerAdInstance = ad;
        return YES;
    } else {
        NSLog(@"[BidonAdapter] New ad instance rejected (current eCPM: %f, new eCPM: %f)",
              self.bannerAdInstance.ecpm,
              ad.ecpm);
        return NO;
    }
}

- (nullable BannerAdInstance *)consumeAd:(double)ecpm {
    if (!self.bannerAdInstance) {
        NSLog(@"[BidonAdapter] No ad available for consumption");
        return nil;
    }

    if (self.registeredEcpm.count < 2) {
        NSLog(@"[BidonAdapter] Not enough eCPM values registered for range check (requested: %f)", ecpm);
        return nil;
    }

    NSUInteger index = [self.registeredEcpm indexOfObject:@(ecpm)];
    if (index == NSNotFound || index == 0) {
        NSLog(@"[BidonAdapter] Cannot find eCPM range: %f", ecpm);
        return nil;
    }

    NSNumber *lowerBound = self.registeredEcpm[index];
    NSNumber *upperBound = self.registeredEcpm[index - 1];

    if (!lowerBound || !upperBound) {
        NSLog(@"[BidonAdapter] Missing bounds for eCPM range check (eCPM: %f)", ecpm);
        return nil;
    }

    double currentEcpm = self.bannerAdInstance.ecpm;

    NSLog(@"[BidonAdapter] Attempting to consume ad with eCPM: %f (range: %@ - %@), current ad eCPM: %f",
          ecpm, lowerBound, upperBound, currentEcpm);

    if (currentEcpm >= lowerBound.doubleValue && currentEcpm <= upperBound.doubleValue) {
        NSLog(@"[BidonAdapter] Ad with eCPM: %f consumed and removed", currentEcpm);
        BannerAdInstance *consumedAd = self.bannerAdInstance;
        self.bannerAdInstance = nil;
        return consumedAd;
    }

    NSLog(@"[BidonAdapter] No matching ad found in range for eCPM: %f", ecpm);
    return nil;
}

@end
