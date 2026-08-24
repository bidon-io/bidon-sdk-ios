# Changelog

## 13.8.0.0
* Updated to Google-Mobile-Ads-SDK 13.8.0
* SDK 13.7.0: Updated `CGSizeFromGADAdSize` to default to portrait orientation when computing fluid ad widths on background threads
* SDK 13.8.0: Refactored full-screen ad rendering to prevent unintended dismissals during device orientation changes on iPad
* SDK 13.8.0: `GADResponseInfo.loadedAdNetworkResponseInfo.adNetworkClassName` now returns the custom event class name instead of `GADMAdapterCustomEvents`

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