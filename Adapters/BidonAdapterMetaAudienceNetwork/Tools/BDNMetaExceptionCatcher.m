//
//  BDNMetaExceptionCatcher.m
//  BidonAdapterMetaAudienceNetwork
//
//  Created by Bidon Team on 23.03.2026.
//

#import "BDNMetaExceptionCatcher.h"

BOOL BDNRunCatchingObjCException(NSError * _Nullable * _Nullable error, void (^block)(void)) {
    @try {
        block();
        return YES;
    } @catch (NSException *exception) {
        if (error) {
            NSString *reason = exception.reason ?: @"Unknown Objective-C exception";
            *error = [NSError errorWithDomain:@"com.bidon.adapter.meta"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: reason}];
        }
        return NO;
    }
}
