//
//  AdKeeper.m
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 21/03/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import "FullscreenAdKeeper.h"

@interface FullscreenAdKeeper ()

@property (nonatomic, strong) NSMutableArray<NSNumber *> *registeredEcpm;
@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, strong, nullable) FullscreenAdInstance *fullscreenAdInstance;

@end

@implementation FullscreenAdKeeper

- (instancetype)initWithAdUnitId:(NSString *)adUnitId {
    self = [super init];
    if (self) {
        self.adUnitId = adUnitId;
        _registeredEcpm = [NSMutableArray new];
    }
    return self;
}

- (void)registerEcpm:(double)ecpm {
    NSLog(@"[BidonAdapter] [%@] Registering eCPM: %f", self.adUnitId, ecpm);
    if (![self.registeredEcpm containsObject:@(ecpm)]) {
        [self.registeredEcpm addObject:@(ecpm)];
    }
    self.lastEcpm = ecpm;
    NSMutableString *values = [NSMutableString new];
    for (int i = 0; i < self.registeredEcpm.count; i++) {
        [values appendFormat:@"%@, ", self.registeredEcpm[i]];
    }
//    NSLog(@"[BidonAdapter] Current registered eCPM values: %@", values);
}

- (BOOL)keepAd:(FullscreenAdInstance *)ad {
    if (!self.fullscreenAdInstance || self.fullscreenAdInstance.ecpm < ad.ecpm) {
        NSLog(@"[BidonAdapter] [%@] Keeping new ad instance with eCPM: %f (previous: %@)",
              self.adUnitId,
              ad.ecpm,
              self.fullscreenAdInstance ? @(self.fullscreenAdInstance.ecpm) : @"none");

        NSString *markedDemandId = [NSString stringWithFormat:@"maxca_%@", self.fullscreenAdInstance.demandId];
        [self.fullscreenAdInstance.adInstance notifyLossWithExternalDemandId:markedDemandId price:ad.ecpm];
        
        self.fullscreenAdInstance = ad;
        return YES;
    } else {
        NSLog(@"[BidonAdapter] [%@] New ad instance rejected (current eCPM: %f, new eCPM: %f)",
              self.adUnitId,
              self.fullscreenAdInstance.ecpm,
              ad.ecpm);
        return NO;
    }
}

- (nullable FullscreenAdInstance *)consumeAd:(double)ecpm {
    if (!self.fullscreenAdInstance) {
        NSLog(@"[BidonAdapter] [%@] No ad available for consumption", self.adUnitId);
        return nil;
    }

    if (self.registeredEcpm.count < 2) {
        NSLog(@"[BidonAdapter] [%@] Not enough eCPM values registered for range check (requested: %f)", self.adUnitId, ecpm);
        return nil;
    }

    NSUInteger index = [self.registeredEcpm indexOfObject:@(ecpm)];
    if (index == NSNotFound || index == 0) {
        NSLog(@"[BidonAdapter] [%@] Cannot find eCPM range: %f", self.adUnitId, ecpm);
        return nil;
    }

    NSNumber *lowerBound = self.registeredEcpm[index];
    NSNumber *upperBound = self.registeredEcpm[index - 1];

    if (!lowerBound || !upperBound) {
        NSLog(@"[BidonAdapter] [%@] Missing bounds for eCPM range check (eCPM: %f)", self.adUnitId, ecpm);
        return nil;
    }

    double currentEcpm = self.fullscreenAdInstance.ecpm;

    NSLog(@"[BidonAdapter] [%@] Attempting to consume ad with eCPM: %f (range: %@ - %@), current ad eCPM: %f",
          self.adUnitId, ecpm, lowerBound, upperBound, currentEcpm);

    if (currentEcpm >= lowerBound.doubleValue && currentEcpm <= upperBound.doubleValue) {
        NSLog(@"[BidonAdapter] [%@] Ad with eCPM: %f consumed and removed", self.adUnitId, currentEcpm);
        FullscreenAdInstance *consumedAd = self.fullscreenAdInstance;
        self.fullscreenAdInstance = nil;
        return consumedAd;
    }

    NSLog(@"[BidonAdapter] [%@] No matching ad found in range for eCPM: %f", self.adUnitId, ecpm);
    return nil;
}

@end
