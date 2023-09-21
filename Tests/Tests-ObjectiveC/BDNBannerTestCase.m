//
//  BDNBannerTestCase.m
//  Tests-ObjectiveC
//
//  Created by Bidon Team on 08.02.2023.
//

#import <XCTest/XCTest.h>
#import <Bidon/Bidon.h>


@interface BDNBannerTestCase : XCTestCase <BDNAdViewDelegate>

@property (nonatomic, strong) BDNBannerView *banner;
@property (nonatomic, strong) BDNBannerProvider *provider;

@end


@implementation BDNBannerTestCase

- (void)createBanner {
    self.banner = [[BDNBannerView alloc] initWithFrame:CGRectZero placement:@"default"];
    self.banner.format = BDNBannerFormatBanner;
    self.banner.delegate = self;
    self.banner.translatesAutoresizingMaskIntoConstraints = NO;

    [self.banner loadAdWith:0.1];
}

- (void)createBannerProvider {
    self.provider = [[BDNBannerProvider alloc] init];
    self.provider.format = BDNBannerFormatBanner;
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testProviderIsNotReady {
    [self createBannerProvider];
    XCTAssertFalse(self.provider.isReady);
}

- (void)testProviderIsNotShowing {
    [self createBannerProvider];
    XCTAssertFalse(self.provider.isShowing);
}

- (void)adObject:(id<BDNAdObject>)adObject didFailToLoadAd:(NSError *)error {}

- (void)adObject:(id<BDNAdObject>)adObject didLoadAd:(id<BDNAd>)ad {}

- (void)adView:(UIView<BDNAdView> *)adView didDismissScreen:(id<BDNAd>)ad {}

- (void)adView:(UIView<BDNAdView> *)adView willLeaveApplication:(id<BDNAd>)ad {}

- (void)adView:(UIView<BDNAdView> *)adView willPresentScreen:(id<BDNAd>)ad {}

@end
