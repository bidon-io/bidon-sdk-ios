//
//  BannerAdInstance.h
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 22/04/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Bidon/Bidon.h>

NS_ASSUME_NONNULL_BEGIN

@interface BannerAdInstance : NSObject<NSCopying>

@property (nonatomic, assign) double ecpm;
@property (nonatomic, copy) NSString *demandId;
@property (nonatomic, strong) id<BDNAdView> adInstance;

- (instancetype)initWithEcpm:(double)ecpm
                    demandId:(NSString *)demandId
                  adInstance:(id<BDNAdView>)adInstance;

@end

NS_ASSUME_NONNULL_END
