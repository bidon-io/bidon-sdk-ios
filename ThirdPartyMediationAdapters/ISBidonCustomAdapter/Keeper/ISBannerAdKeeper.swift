
import Foundation

final class ISBannerAdKeeper {
    private var registeredEcpm: [Double] = []
    private var bannerAdInstance: ISBannerAdInstance?

    private let adUnitId: String

    var lastEcpm: Double = 0.0

    init(adUnitId: String) {
        self.adUnitId = adUnitId
    }

    func registerEcpm(_ ecpm: Double) {
        print("[ISBidonCustomAdapter] Registering eCPM: \(ecpm), adUnitId: \(adUnitId)")
        if !registeredEcpm.contains(ecpm) {
            registeredEcpm.append(ecpm)
        }
        lastEcpm = ecpm
        let values = registeredEcpm.map { "\($0)" }.joined(separator: ", ")
        print("[ISBidonCustomAdapter] Current registered eCPM values: \(values), adUnitId: \(adUnitId)")
    }

    func keepAd(_ ad: ISBannerAdInstance) -> Bool {
        if bannerAdInstance == nil || (bannerAdInstance?.ecpm ?? 0.0) < ad.ecpm {
            let previousEcpm = bannerAdInstance?.ecpm
            print("[ISBidonCustomAdapter] Keeping new ad instance with eCPM: \(ad.ecpm) (previous: \(previousEcpm.map { "\($0)" } ?? "none")), adUnitId: \(adUnitId)")

            if let previous = bannerAdInstance {
                let markedDemandId = "lpca_\(previous.demandId)"
                previous.adInstance.notifyLoss(external: markedDemandId, price: ad.ecpm)
            }

            bannerAdInstance = ad
            return true
        } else {
            print("[ISBidonCustomAdapter] New ad instance rejected (current eCPM: \(bannerAdInstance?.ecpm ?? 0.0), new eCPM: \(ad.ecpm)), adUnitId: \(adUnitId)")
            return false
        }
    }

    func consumeAd(_ ecpm: Double) -> ISBannerAdInstance? {
        guard let currentAd = bannerAdInstance else {
            print("[ISBidonCustomAdapter] No ad available for consumption, adUnitId: \(adUnitId)")
            return nil
        }

        guard registeredEcpm.count >= 2 else {
            print("[ISBidonCustomAdapter] Not enough eCPM values registered for range check (requested: \(ecpm)), adUnitId: \(adUnitId)")
            return nil
        }

        guard let index = registeredEcpm.firstIndex(of: ecpm), index > 0 else {
            print("[ISBidonCustomAdapter] Cannot find eCPM range: \(ecpm), adUnitId: \(adUnitId)")
            return nil
        }

        let lowerBound = registeredEcpm[index]
        let upperBound = registeredEcpm[index - 1]

        let currentEcpm = currentAd.ecpm
        print("[ISBidonCustomAdapter] Attempting to consume ad with eCPM: \(ecpm) (range: \(lowerBound) - \(upperBound)), current ad eCPM: \(currentEcpm), adUnitId: \(adUnitId)")

        if currentEcpm >= lowerBound && currentEcpm <= upperBound {
            print("[ISBidonCustomAdapter] Ad with eCPM: \(currentEcpm) consumed and removed, adUnitId: \(adUnitId)")
            bannerAdInstance = nil
            registeredEcpm.removeAll()
            return currentAd
        }

        print("[ISBidonCustomAdapter] No matching ad found in range for eCPM: \(ecpm), adUnitId: \(adUnitId)")
        return nil
    }
}
