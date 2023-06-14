platform :ios, '12.0'
workspace 'Bidon.xcworkspace'

source 'https://github.com/appodeal/CocoaPods.git'
source 'https://cdn.cocoapods.org/'

install! 'cocoapods', :warn_for_multiple_pod_sources => false
use_frameworks!

# Defenitions

def applovin
  pod 'AppLovinSDK'
end

def bidmachine 
  pod 'BidMachine', '~> 2.1.0.0'
end

def admob
  pod 'Google-Mobile-Ads-SDK'
end

def appsflyer
  pod 'AppsFlyerFramework', '~> 6.10.1'
  pod 'AppsFlyer-AdRevenue', '~> 6.9.0'
end

def dtexchange
  pod 'Fyber_Marketplace_SDK'
end

def unity_ads
  pod 'UnityAds'
end

def ocmock
  pod 'OCMock', '~> 3.9.1'
end

def appodeal_mediation
  pod 'APDAdColonyAdapter', '3.1.3.0-beta.1'
  pod 'APDAdjustAdapter', '3.1.3.0-beta.1'
  pod 'APDAppLovinAdapter', '3.1.3.1-beta.1'
  pod 'APDAppsFlyerAdapter', '3.1.3.1-beta.1'
  pod 'APDBidMachineAdapter', '3.1.3.1-beta.1' # Required
  pod 'APDFirebaseAdapter', '3.1.3.1-beta.1'
  pod 'APDGoogleAdMobAdapter', '3.1.3.1-beta.1'
  pod 'APDIABAdapter', '3.1.3.0-beta.1' # Required
  pod 'APDIronSourceAdapter', '3.1.3.0-beta.1'
  pod 'APDFacebookAdapter', '3.1.3.1-beta.1'
  pod 'APDMetaAudienceNetworkAdapter', '3.1.3.1-beta.1'
  pod 'APDMyTargetAdapter', '3.1.3.1-beta.1'
  pod 'APDStackAnalyticsAdapter', '3.1.3.0-beta.1' # Required
  pod 'APDUnityAdapter', '3.1.3.1-beta.1'
  pod 'APDVungleAdapter', '3.1.3.1-beta.1'
  pod 'APDYandexAdapter', '3.1.3.0-beta.1'
end

# Targets

target 'BidonAdapterBidMachine' do
  project 'Adapters/Adapters.xcodeproj'
  bidmachine
end

target 'BidonAdapterGoogleMobileAds' do
  project 'Adapters/Adapters.xcodeproj'
  admob
end

target 'BidonAdapterAppLovin' do
  project 'Adapters/Adapters.xcodeproj'
  applovin
end

target 'BidonAdapterDTExchange' do
  project 'Adapters/Adapters.xcodeproj'
  dtexchange
end

target 'BidonAdapterUnityAds' do
  project 'Adapters/Adapters.xcodeproj'
  unity_ads
end

# Tests

target 'Tests-ObjectiveC' do
  project 'Tests/Tests.xcodeproj'
  ocmock
  applovin
  bidmachine
  admob
  applovin
  dtexchange
  unity_ads
end


# Demo

target 'Sandbox' do
  project 'Sandbox/Sandbox.xcodeproj'
  applovin
  appsflyer
  bidmachine
  admob
  applovin
  dtexchange
  unity_ads
  appodeal_mediation
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
    end

    installer.pods_project.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '5.0'
      config.build_settings['IOS_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end

