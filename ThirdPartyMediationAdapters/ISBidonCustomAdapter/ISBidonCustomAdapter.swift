
import Foundation
import IronSource
import Bidon

@objc(ISBidonCustomAdapter)
@objcMembers
public final class ISBidonCustomAdapter: ISBaseNetworkAdapter {

    public override func networkSDKVersion() -> String {
       return BidonSdk.sdkVersion
    }

    public override func adapterVersion() -> String {
       return "\(BidonSdk.sdkVersion).0.0"
    }

    public override func `init`(_ adData: ISAdData, delegate: ISNetworkInitializationDelegate) {
        guard !BidonSdk.isInitialized else {
            delegate.onInitDidSucceed()
            return
        }

        guard let appKey = adData.configuration["appKey"] as? String,
              !appKey.isEmpty
        else {
            print("[ISBidonCustomAdapter] ISBidonCustomAdapter init failure")
            delegate.onInitDidFailWithErrorCode(ISAdapterErrors.missingParams.rawValue, errorMessage: "Bidon SDK initialization failed: Missing app key")
            return
        }

        BidonSdk.logLevel = .verbose
        BidonSdk.baseURL = "https://b.appbaqend.com"
        BidonSdk.registerDefaultAdapters()

        BidonSdk.initialize(appKey: appKey) {
            print("[ISBidonCustomAdapter] ISBidonCustomAdapter init successed")

            delegate.onInitDidSucceed()
        }
    }

    public override func setConsent(_ consent: Bool) {
        print("[ISBidonCustomAdapter] ISBidonCustomAdapter consent setted")
    }

    public override func setNetworkData(_ networkData: (ISAdapterNetworkData)!) {
        print("[ISBidonCustomAdapter] ISBidonCustomAdapter networkData setted")
        guard let regulations = networkData.allData() else { return }

        regulations.forEach { key, value in
            guard
                let keyValue = key as? String,
                let boolValue = value as? Bool
            else {
                return
            }

            switch keyValue {
            case "BidonCA_GDPR":
                BidonSdk.regulations.gdpr = boolValue ? .applies : .doesNotApply
            case "BidonCA_CCPA":
                let usPrivacyConsentString = "1YY-"
                let usPrivacyNoConsentString = "1YN-"
                BidonSdk.regulations.usPrivacyString = boolValue ? usPrivacyConsentString : usPrivacyNoConsentString
            case "BidonCA_COPPA":
                BidonSdk.regulations.coppa = boolValue ? .yes : .no
            default:
                break
            }
        }
    }

}
