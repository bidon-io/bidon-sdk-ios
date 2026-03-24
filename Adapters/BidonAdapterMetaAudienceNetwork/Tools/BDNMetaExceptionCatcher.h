//
//  BDNMetaExceptionCatcher.h
//  BidonAdapterMetaAudienceNetwork
//
//  Created by Bidon Team on 23.03.2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Executes the block inside an Objective-C @try/@catch.
/// Meta Audience Network SDK may throw doesNotRecognizeSelector exceptions in
/// pure SwiftUI apps (no traditional UIApplicationDelegate.window) when
/// FBAdUtility attempts to locate the current UIWindow via private UIKit APIs.
/// Returns YES if the block ran without an exception; NO otherwise,
/// setting *error to the caught exception's reason.
BOOL BDNRunCatchingObjCException(NSError * _Nullable * _Nullable error, void (^block)(void));

NS_ASSUME_NONNULL_END
