//
//  FullscreenAdInstance.h
//  BidonMediationAdapter
//
//  Created by Евгения Григорович on 21/03/2025.
//  Copyright © 2025 Appodeal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Bidon/Bidon-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface FullscreenAdInstance : NSObject <NSCopying>

@property (nonatomic, assign) double ecpm;
@property (nonatomic, copy) NSString *demandId;
@property (nonatomic, strong) id<BDNFullscreenAd> adInstance;

- (instancetype)initWithEcpm:(double)ecpm
                    demandId:(NSString *)demandId
                  adInstance:(id<BDNFullscreenAd>)adInstance;

@end

NS_ASSUME_NONNULL_END
