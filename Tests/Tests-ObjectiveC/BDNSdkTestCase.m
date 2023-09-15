//
//  BidonSdkTestCase.m
//  Tests-ObjectiveC
//
//  Created by Bidon Team on 08.02.2023.
//

#import <XCTest/XCTest.h>
#import <Bidon/Bidon.h>


@interface BDNSdkTestCase : XCTestCase

@end


@implementation BDNSdkTestCase

- (void)setUp {
    
}

- (void)tearDown {
    
}

- (void)testRegisterDefaultAdapter {
    [BDNSdk registerDefaultAdapters];
}

- (void)testSetLogLevel {
    [BDNSdk setLogLevel:BDNLoggerLevelDebug];
}

- (void)testInitialize {
    [BDNSdk initializeWithAppKey:@"APP KEY" completion:^{
            
    }];
}

- (void)testRegisterAdapters {
    [BDNSdk registerAdapterWithClassName:@"BidonAdapterAppLovin.AppLovinDemandSourceAdapter"];
    [BDNSdk registerAdapterWithClassName:@"BidonAdapterGoogleMobileAds.GoogleMobileAdsDemandSourceAdapter"];
}

- (void)testExtas {
    [BDNSdk setExtraValue:nil for:@"some_extras"];
    id extras = [BDNSdk extras];
    XCTAssertNotNil(extras);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
