//
//  BannerAdInstance.h
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 22/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Bidon/Bidon-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface BannerAdInstance : NSObject<NSCopying>

@property (nonatomic, assign) double ecpm;
@property (nonatomic, copy) NSString *demandId;
@property (nonatomic, strong) id<BDNAdView> adInstance;
@property (nonatomic, strong) id<BDNAd> ad;

- (instancetype)initWithEcpm:(double)ecpm
                    demandId:(NSString *)demandId
                          ad:(id<BDNAd>)ad
                  adInstance:(id<BDNAdView>)adInstance;

@end

NS_ASSUME_NONNULL_END
