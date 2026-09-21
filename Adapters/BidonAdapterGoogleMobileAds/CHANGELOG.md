# Changelog

## 13.10.0.0
* Updated to Google-Mobile-Ads-SDK 13.10.0

## 13.9.0.0
* Updated to Google-Mobile-Ads-SDK 13.9.0
* Added support for swipeable interstitial ads signal collection and rendering APIs (`GADSwipeableInterstitialSignalRequest`, `+loadWithAdResponseString:completionHandler:`)
* `GADResponseInfo.loadedAdNetworkResponseInfo.adNetworkClassName` now returns the custom event class name instead of `GADMAdapterCustomEvents`
* Refactored full-screen ad validation logic to prevent unintended dismissals during device orientation changes on iPad
* Added `GADDisableAdInspector` plist key to disable ad inspector functionality
* `CGSizeFromGADAdSize` now defaults to portrait orientation when computing fluid ad widths on a background thread

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

## 13.0.0.0
* Updated to Google-Mobile-Ads-SDK 13.0.0

## 12.14.0.0
* Updated to Google-Mobile-Ads-SDK 12.14.0