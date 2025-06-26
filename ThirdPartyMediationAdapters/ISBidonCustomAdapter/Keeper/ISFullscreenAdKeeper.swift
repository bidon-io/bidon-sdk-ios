
import Foundation
import Bidon

final class ISFullscreenAdKeeper {
    private var registeredEcpm: [Double] = []
    private var fullscreenAdInstance: ISFullscreenAdInstance?

    private let adUnitId: String

    var lastEcpm: Double = 0.0

    init(adUnitId: String) {
        self.adUnitId = adUnitId
    }

    func registerEcpm(_ ecpm: Double) {
        print("[ISBidonCustomAdapter] ISFullscreenAdKeeper > Registering eCPM: \(ecpm), adUnitId: \(adUnitId)")
        if !registeredEcpm.contains(ecpm) {
            registeredEcpm.append(ecpm)
        }
        lastEcpm = ecpm
        let values = registeredEcpm.map { "\($0)" }.joined(separator: ", ")
        print("[ISBidonCustomAdapter] ISFullscreenAdKeeper > Current registered eCPM values: \(values), adUnitId: \(adUnitId)")
    }

    func keepAd(_ ad: ISFullscreenAdInstance) -> Bool {
        if fullscreenAdInstance == nil || (fullscreenAdInstance?.ecpm ?? 0.0) < ad.ecpm {
            let previousEcpm = fullscreenAdInstance?.ecpm
            print("[ISBidonCustomAdapter] ISFullscreenAdKeeper > Keeping new ad instance with eCPM: \(ad.ecpm) (previous: \(previousEcpm.map { "\($0)" } ?? "none")), adUnitId: \(adUnitId)")

            if let previous = fullscreenAdInstance {
                let markedDemandId = "lpca_\(previous.demandId)"
                previous.adInstance.notifyLoss(external: markedDemandId, price: ad.ecpm)
            }

            fullscreenAdInstance = ad
            return true
        } else {
            print("[ISBidonCustomAdapter] ISFullscreenAdKeeper > New ad instance rejected (current eCPM: \(fullscreenAdInstance?.ecpm ?? 0.0), new eCPM: \(ad.ecpm)), adUnitId: \(adUnitId)")
            return false
        }
    }

    func consumeAd(_ ecpm: Double) -> ISFullscreenAdInstance? {
        guard let currentAd = fullscreenAdInstance else {
            print("[ISBidonCustomAdapter] ISFullscreenAdKeeper > No ad available for consumption, adUnitId: \(adUnitId)")
            return nil
        }

        guard registeredEcpm.count >= 2 else {
            print("[ISBidonCustomAdapter] ISFullscreenAdKeeper > Not enough eCPM values registered for range check (requested: \(ecpm)), adUnitId: \(adUnitId)")
            return nil
        }

        guard let index = registeredEcpm.firstIndex(of: ecpm), index > 0 else {
            print("[ISBidonCustomAdapter] ISFullscreenAdKeeper > Cannot find eCPM range: \(ecpm)")
            return nil
        }

        let lowerBound = registeredEcpm[index]
        let upperBound = registeredEcpm[index - 1]

        let currentEcpm = currentAd.ecpm
        print("[ISBidonCustomAdapter] ISFullscreenAdKeeper > Attempting to consume ad with eCPM: \(ecpm) (range: \(lowerBound) - \(upperBound)), current ad eCPM: \(currentEcpm), adUnitId: \(adUnitId)")

        if currentEcpm >= lowerBound && currentEcpm <= upperBound {
            print("[ISBidonCustomAdapter] ISFullscreenAdKeeper > Ad with eCPM: \(currentEcpm) consumed and removed, adUnitId: \(adUnitId)")
            fullscreenAdInstance = nil
            registeredEcpm.removeAll()
            return currentAd
        }

        print("[ISBidonCustomAdapter] ISFullscreenAdKeeper > No matching ad found in range for eCPM: \(ecpm), adUnitId: \(adUnitId)")
        return nil
    }
}
