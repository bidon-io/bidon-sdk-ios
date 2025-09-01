platform :ios, '13.0'
workspace 'Bidon.xcworkspace'

source 'https://github.com/appodeal/CocoaPods.git'
source 'https://cdn.cocoapods.org/'

install! 'cocoapods', :warn_for_multiple_pod_sources => false
use_frameworks! 

# Defenitions

def amazon
  pod 'AmazonPublisherServicesSDK', '~> 5.3.0'
end

def applovin
  pod 'AppLovinSDK', '~> 13.3.1'
end

def bidmachine 
  pod 'BidMachine', '~> 3.4.0'
end

def admob
  pod 'Google-Mobile-Ads-SDK', '~> 12.8'
end

def appsflyer
  pod 'AppsFlyerFramework', '~> 6.15.2'
end

def bigo_ads
  pod 'BigoADS', '~> 4.9.0'
end

def dtexchange
  pod 'Fyber_Marketplace_SDK', '~> 8.3.8'
end

def meta_ads
  pod 'FBAudienceNetwork', '~> 6.20.1'
end

def unity_ads
  pod 'UnityAds', '~> 4.14.2'
end

def mintegral
  pod 'MintegralAdSDK', '~> 7.7.7'
end

def mobilefuse
  pod 'MobileFuseSDK', '1.9.0'
end

def moloco
  pod 'MolocoSDKiOS', '~> 3.12.0'
end

def vungle
  pod 'VungleAds', '7.5.1'
end

def ocmock
  pod 'OCMock', '~> 3.9.4'
end

def meta_sdk
  pod 'FBSDKLoginKit', '~> 17.1.0'
end

def unity_ads
  pod 'UnityAds', '~> 4.16.0'
end

def mintegral
  pod 'MintegralAdSDK', '~> 7.7.9'
end

def mobilefuse
  pod 'MobileFuseSDK', '~> 1.9.2'
end

def vungle
  pod 'VungleAds', '~> 7.5.2'
end

def inmobi
  pod 'InMobiSDK', '~> 10.8.6'
end

def my_target
  pod "myTargetSDK", '~> 5.33.0'
end

def chartboost
  pod 'ChartboostSDK', '~> 9.9.2'
end

def ironsource
  pod "IronSourceSDK", "~> 8.10.0"
end

def yandex
  pod 'DivKit', '32.6.0'
  pod 'AppMetricaAnalytics', '~> 5.11.2'
  pod 'YandexMobileAds', "~> 7.14.1"
end


def appodeal_mediation
  # pod 'Appodeal', '~> 3.3.0'
  # pod 'APDAdColonyAdapter', '3.1.3.0'
  # pod 'APDAdjustAdapter', '3.1.3.0'
  # pod 'APDAppLovinAdapter', '3.1.3.0'
  # pod 'APDAppsFlyerAdapter', '3.1.3.0'
  # pod 'APDBidMachineAdapter', '3.1.3.0' # Required
  # pod 'APDFirebaseAdapter', '3.1.3.0'
  # pod 'APDGoogleAdMobAdapter', '3.1.3.0'
  # pod 'APDIABAdapter', '3.1.3.0' # Required
  # pod 'APDIronSourceAdapter', '3.1.3.0'
  # pod 'APDFacebookAdapter', '3.1.3.0'
  # pod 'APDMetaAudienceNetworkAdapter', '3.1.3.0'
  # pod 'APDMyTargetAdapter', '3.1.3.0'
  # pod 'APDStackAnalyticsAdapter', '3.1.3.0' # Required
#   pod 'APDUnityAdapter', '3.1.3.0'
#   pod 'APDVungleAdapter', '3.1.3.0'
#   pod 'APDYandexAdapter', '3.1.3.0'
end

def consent_manager
  pod "StackConsentManager", '~> 3.0.0'
end

def swiftlint
  pod 'SwiftLint'
end

def ocmock
  pod 'OCMock', '~> 3.9.4'
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

target 'BidonAdapterGoogleAdManager' do
  project 'Adapters/Adapters.xcodeproj'
  admob
end

target 'BidonAdapterAppLovin' do
  project 'Adapters/Adapters.xcodeproj'
  applovin
end

target 'BidonAdapterBigoAds' do
  project 'Adapters/Adapters.xcodeproj'
  bigo_ads
end

target 'BidonAdapterDTExchange' do
  project 'Adapters/Adapters.xcodeproj'
  dtexchange
end

target 'BidonAdapterInMobi' do
  project 'Adapters/Adapters.xcodeproj'
  inmobi
end

target 'BidonAdapterUnityAds' do
  project 'Adapters/Adapters.xcodeproj'
  unity_ads
end

target 'BidonAdapterMetaAudienceNetwork' do
  project 'Adapters/Adapters.xcodeproj'
  meta_ads
end

target 'BidonAdapterMintegral' do
  project 'Adapters/Adapters.xcodeproj'
  mintegral
end

target 'BidonAdapterMobileFuse' do
  project 'Adapters/Adapters.xcodeproj'
  mobilefuse
end

target 'BidonAdapterMoloco' do
  project 'Adapters/Adapters.xcodeproj'
  moloco
end

target 'BidonAdapterVungle' do
  project 'Adapters/Adapters.xcodeproj'
  vungle
end

target 'BidonAdapterAmazon' do
  project 'Adapters/Adapters.xcodeproj'
  amazon
end

target 'BidonAdapterMyTarget' do
  project 'Adapters/Adapters.xcodeproj'
  my_target
end

target 'BidonAdapterChartboost' do
  project 'Adapters/Adapters.xcodeproj'
  chartboost
end

target 'BidonAdapterIronSource' do
  project 'Adapters/Adapters.xcodeproj'
  ironsource
end

target 'BidonAdapterYandex' do
  project 'Adapters/Adapters.xcodeproj'
  yandex
end

target 'AppLovinMediationBidonAdapter' do
  project 'ThirdPartyMediationAdapters/ThirdPartyMediationAdapters.xcodeproj'
  pod 'AppLovinSDK', '~> 13.1'
end

target 'ISBidonCustomAdapter' do
  project 'ThirdPartyMediationAdapters/ThirdPartyMediationAdapters.xcodeproj'
  pod 'IronSourceSDK', '~> 8.10'
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
  mintegral
  mobilefuse
  moloco
  vungle
  bigo_ads
  meta_ads
  inmobi
  amazon
end

target 'Tests-Swift' do
  project 'Tests/Tests.xcodeproj'
end

# Demo

target 'Sandbox' do
  project 'Sandbox/Sandbox.xcodeproj'
  consent_manager
  swiftlint
  applovin
  appsflyer
  bidmachine
  admob
  applovin
  dtexchange
  unity_ads
  mintegral
  mobilefuse
  moloco
  vungle
  bigo_ads
  meta_ads
  meta_sdk
  inmobi
  amazon
#  appodeal_mediation
  my_target
  chartboost
  ironsource
  yandex
end

post_install do |installer|
  problematic_targets = ['VGSLFundamentals', 'VGSLUI', 'VGSLNetworking', 'VGSL', 'AppMetricaLibraryAdapter']
  
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if problematic_targets.include?(target.name)
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
      else
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
      
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      
      xcconfig_path = config.base_configuration_reference.real_path
      xcconfig = File.read(xcconfig_path)
      xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
      File.open(xcconfig_path, "w") { |file| file.write(xcconfig_mod) }
    end
  end
  
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  end
end
