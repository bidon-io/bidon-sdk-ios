platform :ios, '13.0'
workspace 'Bidon.xcworkspace'

source 'https://cdn.cocoapods.org/'
source "https://github.com/bidon-io/CocoaPods_Specs.git"
source 'https://github.com/appodeal/CocoaPods.git'

install! 'cocoapods', :warn_for_multiple_pod_sources => false
use_frameworks! 

# Defenitions

def amazon
  pod 'AmazonPublisherServicesSDK', '5.3.2'
end

def applovin
  pod 'AppLovinSDK', '13.5.1'
end

def bidmachine 
  pod 'BidMachine', '3.5.0'
end

def admob
  pod 'Google-Mobile-Ads-SDK', '12.13.0'
end

def appsflyer
  pod 'AppsFlyerFramework', '6.17.7'
end

def bigo_ads
  pod 'BigoADS', '5.0.0'
end

def dtexchange
  pod 'Fyber_Marketplace_SDK', '8.4.1'
end

def meta_ads
  pod 'FBAudienceNetwork', '6.20.1'
end

def unity_ads
  pod 'UnityAds', '4.16.3'
end

def moloco
  pod 'MolocoSDKiOS', '4.1.0'
end

def meta_sdk
  pod 'FBSDKLoginKit', '~> 17.1.0'
end

def mintegral
  pod 'MintegralAdSDK', '8.0.0'
end

def mobilefuse
  pod 'MobileFuseSDK', '1.9.3'
end

def vungle
  pod 'VungleAds', '7.6.2'
end

def inmobi
  pod 'InMobiSDK', '11.1.0'
end

def my_target
  pod "myTargetSDK", '5.36.2'
end

def chartboost
  pod 'ChartboostSDK', '9.10.1'
end

def ironsource
  pod "IronSourceSDK/Ads", '9.1.0'
end

def yandex
  pod 'YandexMobileAds', '7.17.0'
end

def startio
  pod 'StartAppSDK', '4.11.0'
end

def taurus
  pod 'TaurusxAdsSDK','1.9.2'
end

def consent_manager
  pod "StackConsentManager", '~> 3.0.0'
end

def swiftlint
  pod 'SwiftLint'
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

target 'BidonAdapterStartIo' do
  project 'Adapters/Adapters.xcodeproj'
  startio
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

target 'BidonAdapterTaurusX' do
  project 'Adapters/Adapters.xcodeproj'
  taurus
end

target 'AppLovinMediationBidonAdapter' do
  project 'ThirdPartyMediationAdapters/ThirdPartyMediationAdapters.xcodeproj'
  applovin
end

target 'ISBidonCustomAdapter' do
  project 'ThirdPartyMediationAdapters/ThirdPartyMediationAdapters.xcodeproj'
  ironsource
end

# Tests

target 'Tests-Swift' do
  project 'Tests/Tests.xcodeproj'
end

target 'AdaptersTests' do
  project 'Tests/Tests.xcodeproj'
  amazon
  applovin
  bidmachine
  admob
  bigo_ads
  dtexchange
  meta_ads
  unity_ads
  mintegral
  mobilefuse
  moloco
  startio
  vungle
  inmobi
  my_target
  chartboost
  ironsource
  yandex
  taurus
  startio
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
  startio
  vungle
  bigo_ads
  meta_ads
  meta_sdk
  inmobi
  amazon
  my_target
  chartboost
  ironsource
  yandex
  taurus
#  pod 'BidonAdapterYandex', '7.16.2.0-test.7'
end

post_install do |installer|
  problematic_targets = ['VGSLFundamentals', 'VGSLUI', 'VGSLNetworking', 'VGSL', 'AppMetricaLibraryAdapter', 'DivKitBinaryCompatibilityFacade']
  
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
