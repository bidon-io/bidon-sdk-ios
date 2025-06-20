//
//  DTExchangeInterstitialDemandProvider.swift
//  BidonAdapterDTExchange
//
//  Created by Bidon Team on 27.02.2023.
//

import Foundation
import Bidon
import IASDKCore



class DTExchangeBaseDemandProvider<Controller: IAUnitController>: NSObject {
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

    private(set) var adSpot: IAAdSpot?

    private weak var impressionObserver: DTEXchangeImpressionObserver?

    open func unitController() -> Controller {
        fatalError("DTExchange base demand provider can't provide unit controller")
    }

    init(observer: DTExchangeDefaultImpressionObserver) {
        self.impressionObserver = observer
        super.init()
    }

    deinit {
        guard let spotId = adSpot?.id else { return }
        impressionObserver?.removeObservation(spotId: spotId)
    }
}


extension DTExchangeBaseDemandProvider: DirectDemandProvider {
    func load(
        pricefloor: Price,
        adUnitExtras: DTExchangeAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        let adRequest = IAAdRequest.build { builder in
            builder.spotID = adUnitExtras.spotId
        }

        guard let adRequest = adRequest else {
            response(.failure(.incorrectAdUnitId))
            return
        }

        let adSpot = IAAdSpot.build { builder in
            builder.adRequest = adRequest
            builder.addSupportedUnitController(self.unitController())
        }

        guard let adSpot = adSpot else {
            response(.failure(.unspecifiedException("Failed to build IAAdSpot")))
            return
        }

        adSpot.fetchAd { adSpot, _, error in
            guard let adSpot = adSpot, error == nil else {
                response(.failure(.noFill(error?.localizedDescription)))
                return
            }

            response(.success(adSpot))
        }

        self.adSpot = adSpot
        self.impressionObserver?.observe(spotId: adRequest.spotID) { [weak self] adRevenue in
            guard
                let self = self,
                let adSpot = self.adSpot
            else { return }

            self.revenueDelegate?.provider(
                self,
                didPayRevenue: adRevenue,
                ad: adSpot
            )
        }
    }

    func notify(ad: IAAdSpot, event: DemandProviderEvent) {}
}
