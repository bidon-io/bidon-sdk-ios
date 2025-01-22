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
    
    private var adSpot: IAAdSpot?
    private(set) var adWrapper: DTExchangeDemandAdWrapper?
    
    private weak var impressionObserver: DTEXchangeImpressionObserver?
    
    open func unitController() -> Controller {
        fatalError("DTExchange base demand provider can't provide unit controller")
    }
    
    init(observer: DTExchangeDefaultImpressionObserver) {
        self.impressionObserver = observer
        super.init()
    }
    
    deinit {
        guard let spotId = adWrapper?.spotId else { return }
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
        let adWrapper = DTExchangeDemandAdWrapper(id: adSpot?.id ?? String(hash))
        print("!!! DTExchange > adSpot id: \(adSpot?.id), adWrapper id: \(adWrapper.id), adRequest id: \(adRequest.unitID)")
        
        guard let adSpot = adSpot else {
            response(.failure(.unscpecifiedException("Failed to build IAAdSpot")))
            return
        }
        
        adSpot.fetchAd { adSpot, model, error in
            guard let adSpot = adSpot, error == nil else {
                response(.failure(.noFill(error?.localizedDescription)))
                return
            }
    
//            response(.success(adSpot))
            response(.success(adWrapper))
        }
        
        adWrapper.spotId = adRequest.spotID
        self.adSpot = adSpot
        self.adWrapper = adWrapper
        self.impressionObserver?.observe(spotId: adRequest.spotID) { [weak self] adRevenue, dsp in
            guard
                let self,
                let adWrapper = self.adWrapper
            else { return }
            
            print("!!! DTExchange > impressionObserver > adSpot id: \(adSpot.id), adWrapper id: \(adWrapper.id)")
            adWrapper.dsp = dsp ?? ""
            self.revenueDelegate?.provider(
                self,
                didPayRevenue: adRevenue,
                ad: adWrapper
            )
        }
    }
    
    func notify(ad: IAAdSpot, event: DemandProviderEvent) {}
}
