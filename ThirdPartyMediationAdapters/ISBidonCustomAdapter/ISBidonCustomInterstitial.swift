
import IronSource
import Bidon

@objc(ISBidonCustomInterstitial)
@objcMembers
public final class ISBidonCustomInterstitial: ISBaseInterstitial {

    private weak var interstitialDelegate: ISInterstitialAdDelegate?
    private var interstitialAd: Interstitial?
    private var placementId: String = "UNDEFINED"
    private var maxEcpm: Double = 0.0
    private var adUnitId: String = ""


    public override func loadAd(with adData: ISAdData, delegate: ISInterstitialAdDelegate) {
        print("[ISBidonCustomAdapter] Interstitial start ---------------------------------------")
        interstitialDelegate = delegate
        adUnitId = adData.adUnitData?["adUnitId"] as? String ?? ""
        let configuration = adData.configuration
        placementId = configuration["instanceName"] as? String ?? "UNDEFINED"
        let ecpm = Double((configuration["price"] as? String) ?? "0") ?? 0.0
        maxEcpm = ecpm
        let stringValue = configuration["should_load"] as? String ?? "false"
        let shouldLoadAd = Bool(stringValue) ?? false

        print("[ISBidonCustomAdapter] Interstitial start load Ad, shouldLoadAd: \(shouldLoadAd), Placement ID: \(placementId), adUnitId: \(adUnitId)")
        let keeperInterstitial = ISAdKeeperFactory.shared.getInterstitial(adUnitId)
        let lastRegisteredEcpm = keeperInterstitial.lastEcpm
        keeperInterstitial.registerEcpm(ecpm)

        if shouldLoadAd {
            let auctionKey = configuration["auctionKey"] as? String
            let interstitialAd = Interstitial(auctionKey: auctionKey)
            interstitialAd.setExtraValue("level_play", for: "mediator")
            interstitialAd.setExtraValue(lastRegisteredEcpm, for: "previous_auction_price")
            interstitialAd.delegate = self
            interstitialAd.loadAd(with: 0)
            self.interstitialAd = interstitialAd

        } else {
            print("[ISBidonCustomAdapter] Interstitial > No ext Detected, ECPM: \(maxEcpm), Placement ID: \(placementId), adUnitId: \(adUnitId)")

            if let cachedAd = keeperInterstitial.consumeAd(ecpm) {
                print("[ISBidonCustomAdapter] Interstitial ad loaded from cache, Placement ID: \(placementId), adUnitId: \(adUnitId)")
                interstitialAd = cachedAd.adInstance as? Interstitial
                interstitialAd?.delegate = self
                interstitialDelegate?.adDidLoad()

            } else {
                print("[ISBidonCustomAdapter] Interstitial > loadAd > ad failed to load: No fill, Placement ID: \(placementId), adUnitId: \(adUnitId)")
                interstitialDelegate?.adDidFailToLoadWith(.noFill, errorCode: 0, errorMessage: "Interstitial ad failed to load: No fill, Placement ID: \(placementId)")
            }
        }

    }

    public override func isAdAvailable(with adData: ISAdData) -> Bool {
        guard let interstitialAd else { return false }
        return interstitialAd.isReady
    }

    public override func showAd(with viewController: UIViewController, adData: ISAdData, delegate: ISInterstitialAdDelegate) {
        guard let interstitialAd,
                interstitialAd.isReady else {
            print("[ISBidonCustomAdapter] Interstitial > Failed to present ad because it is nil or is not ready, Placement ID: \(self.placementId), adUnitId: \(adUnitId)")
            interstitialDelegate?.adDidFailToShowWithErrorCode(ISAdapterErrors.internal.rawValue, errorMessage: "Failed to present ad because it is nil or is not ready, Placement ID: \(self.placementId)")
            return
        }

        print("[ISBidonCustomAdapter] Interstitial > Presenting ad, Placement ID: \(self.placementId)")
        DispatchQueue.main.async { [weak interstitialAd] in
            interstitialAd?.showAd(from: viewController)
        }
    }

    func onDestroyInterstitial() {
        interstitialAd = nil
        interstitialDelegate = nil
    }
}


// MARK: - FullscreenAdDelegate
extension ISBidonCustomInterstitial: FullscreenAdDelegate {
    public func fullscreenAd(_ fullscreenAd: any Bidon.FullscreenAdObject, willPresentAd ad: any Bidon.Ad) {
        print("[ISBidonCustomAdapter] Interstitial did show, Placement ID: \(placementId), adUnitId: \(adUnitId)")
        interstitialDelegate?.adDidOpen()
        interstitialDelegate?.adDidShowSucceed()
        interstitialDelegate?.adDidStart()
    }

    public func fullscreenAd(_ fullscreenAd: any Bidon.FullscreenAdObject, didDismissAd ad: any Bidon.Ad) {
        print("[ISBidonCustomAdapter] Interstitial did close ad, Placement ID: \(placementId), adUnitId: \(adUnitId)")
        interstitialDelegate?.adDidEnd()
        interstitialDelegate?.adDidClose()
    }

    public func adObject(_ adObject: any AdObject, didRecordClick ad: any Ad) {
        print("[ISBidonCustomAdapter] Interstitial did record click, Placement ID: \(placementId), adUnitId: \(adUnitId)")
        interstitialDelegate?.adDidClick()
    }

    public func adObject(_ adObject: any Bidon.AdObject, didLoadAd ad: any Bidon.Ad, auctionInfo: any Bidon.AuctionInfo) {
        guard let interstitialAd else {
            print("[ISBidonCustomAdapter] Interstitial > FullscreenAdDelegate > ad failed to load: Ad is null, Placement ID: \(placementId), adUnitId: \(adUnitId)")
            interstitialDelegate?.adDidFailToLoadWith(.noFill, errorCode: 0, errorMessage: "Interstitial ad failed to load: No fill, Placement ID: \(placementId)")
            onDestroyInterstitial()
            return
        }

        let price = ad.price
        print("[ISBidonCustomAdapter] Interstitial ad loaded, Placement ID: \(placementId) ECPM: \(price), adUnitId: \(adUnitId)")

        let adInstance = ISFullscreenAdInstance(
            ecpm: price,
            demandId: ad.adUnit.demandId,
            adInstance: interstitialAd
        )

        let interstitialAdKeeper = ISAdKeeperFactory.shared.getInterstitial(adUnitId)
        if interstitialAdKeeper.keepAd(adInstance) {
            print("[ISBidonCustomAdapter] Interstitial ad kept in cache, Placement ID: \(placementId)")
        } else {
            print("[ISBidonCustomAdapter] Interstitial ad failed to keep in cache: cache is full, Placement ID: \(placementId), adUnitId: \(adUnitId)")
            onDestroyInterstitial()
        }

        if let cachedAd = interstitialAdKeeper.consumeAd(maxEcpm) {
            print("[ISBidonCustomAdapter] Interstitial ad loaded from cache, Placement ID: \(placementId), adUnitId: \(adUnitId)")
            self.interstitialAd = cachedAd.adInstance as? Interstitial
            self.interstitialAd?.delegate = self
            interstitialDelegate?.adDidLoad()
        } else {
            print("[ISBidonCustomAdapter] Interstitial ad failed to load from cache: No fill, Placement ID: \(placementId), adUnitId: \(adUnitId)")
            interstitialDelegate?.adDidFailToLoadWith(.noFill, errorCode: 0, errorMessage: "Interstitial ad failed to load from cache: No fill, Placement ID: \(placementId)")
        }
    }

    public func adObject(_ adObject: any Bidon.AdObject, didFailToLoadAd error: any Error, auctionInfo: any Bidon.AuctionInfo) {
        print("[ISBidonCustomAdapter] Interstitial > FullscreenAdDelegate > ad failed to load, error: \(error)")
        interstitialDelegate?.adDidFailToLoadWith(.noFill, errorCode: 0, errorMessage: error.localizedDescription)
        onDestroyInterstitial()
    }
}
