# Changelog

## 13.9.0.0
* Updated to Google-Mobile-Ads-SDK 13.9.0
* Google SDK 13.7.0: `CGSizeFromGADAdSize` now defaults to portrait orientation when computing fluid ad widths on a background thread
* Google SDK 13.8.0: `GADResponseInfo.loadedAdNetworkResponseInfo.adNetworkClassName` now returns the custom event class name for custom event ad sources instead of `GADMAdapterCustomEvents`; refactored screen-fit validation for full-screen ads to prevent unintended dismissals during orientation changes on iPad; added `GADDisableAdInspector` plist key
* Google SDK 13.9.0: Added swipeable interstitial signal collection and rendering APIs (`GADSwipeableInterstitialAd.loadWithAdResponseString:completionHandler:`, `GADSwipeableInterstitialSignalRequest`)

## 13.6.0.0
* Updated to Google-Mobile-Ads-SDK 13.6.0
* Fixed Xcode compiler warnings caused by missing beta header files in the SDK umbrella header

## 13.5.0.0
* Updated to Google-Mobile-Ads-SDK 13.5.0

## 13.4.0.0
* Updated to Google-Mobile-Ads-SDK 13.4.0
* Fixed missing beta header files in umbrella header that caused Xcode compiler warnings (regression from 13.3.0)
* Improved thread safety for native ad rendering by ensuring media views are always accessed on the main thread

## 13.3.0.0
* Updated to Google-Mobile-Ads-SDK 13.3.0

## 13.1.0.0
* Updated to Google-Mobile-Ads-SDK 13.1.0

## 12.14.0.0
* Updated to Google-Mobile-Ads-SDK 12.14.0