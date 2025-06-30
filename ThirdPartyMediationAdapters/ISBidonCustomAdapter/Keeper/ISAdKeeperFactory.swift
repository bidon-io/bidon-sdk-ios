
import Bidon
import IronSource

final class ISAdKeeperFactory {
    static let shared = ISAdKeeperFactory()

    private var interstitialStore = [String: ISFullscreenAdKeeper]()
    private let interstitialLock = NSLock()

    private var rewardedStore = [String: ISFullscreenAdKeeper]()
    private let rewardedLock = NSLock()

    private var bannerStore = [String: ISBannerAdKeeper]()
    private let bannerLock = NSLock()


    func getInterstitial(_ adUnitId: String) -> ISFullscreenAdKeeper {
        interstitialLock.lock()
        defer { interstitialLock.unlock() }

        if let adKeeper = interstitialStore[adUnitId] {
            return adKeeper
        } else {
            let newAdKeeper = ISFullscreenAdKeeper(adUnitId: adUnitId)
            interstitialStore[adUnitId] = newAdKeeper
            return newAdKeeper
        }
    }

    func getRewarded(_ adUnitId: String) -> ISFullscreenAdKeeper {
        rewardedLock.lock()
        defer { rewardedLock.unlock() }

        if let adKeeper = rewardedStore[adUnitId] {
            return adKeeper
        } else {
            let newAdKeeper = ISFullscreenAdKeeper(adUnitId: adUnitId)
            rewardedStore[adUnitId] = newAdKeeper
            return newAdKeeper
        }
    }

    func getBanner(_ adUnitId: String) -> ISBannerAdKeeper {
        bannerLock.lock()
        defer { bannerLock.unlock() }

        if let adKeeper = bannerStore[adUnitId] {
            return adKeeper
        } else {
            let newAdKeeper = ISBannerAdKeeper(adUnitId: adUnitId)
            bannerStore[adUnitId] = newAdKeeper
            return newAdKeeper
        }
    }

}
