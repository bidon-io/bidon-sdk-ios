//
//  DTExchangeInterstitialDemandProvider.swift
//  BidonAdapterDTExchange
//
//  Created by Bidon Team on 27.02.2023.
//

import Foundation
import Bidon
import IASDKCore
import UIKit


final class DTExchangeInterstitialDemandProvider: DTExchangeBaseDemandProvider<IAFullscreenUnitController> {
    private weak var rootViewController: UIViewController?

    weak var rewardDelegate: DemandProviderRewardDelegate?

    private lazy var mraidController = IAMRAIDContentController.build { builder in
        builder.mraidContentDelegate = self
    }

    private lazy var videoController = IAVideoContentController.build { builder in
        builder.videoContentDelegate = self
    }

    private lazy var controller: IAFullscreenUnitController = {
        let controller = IAFullscreenUnitController.build { [unowned self] builder in
            self.mraidController.map(builder.addSupportedContentController)
            self.videoController.map(builder.addSupportedContentController)
            builder.unitDelegate = self
        }

        guard let controller = controller else { fatalError("Unable to create IAFullscreenUnitController controller") }
        return controller
    }()

    override func unitController() -> IAFullscreenUnitController {
        return controller
    }
}


extension DTExchangeInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: IAAdSpot, from viewController: UIViewController) {
        guard
            ad.activeUnitController === controller,
            controller.isReady()
        else {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .invalidPresentationState
            )
            return
        }

        self.rootViewController = viewController

        controller.showAd(animated: true)
    }
}


extension DTExchangeInterstitialDemandProvider: RewardedAdDemandProvider {}


extension DTExchangeInterstitialDemandProvider: IAMRAIDContentDelegate {}


extension DTExchangeInterstitialDemandProvider: IAVideoContentDelegate {
    func iaVideoContentController(
        _ contentController: IAVideoContentController?,
        videoInterruptedWithError error: Error
    ) {
        guard let adSpot = adSpot else { return }
        delegate?.provider(
            self,
            didFailToDisplayAd: adSpot,
            error: .generic(error: error)
        )
    }
}


extension DTExchangeInterstitialDemandProvider: IAUnitDelegate {
    func iaParentViewController(for unitController: IAUnitController?) -> UIViewController {
        return rootViewController ?? UIApplication.shared.bd.topViewcontroller ?? UIViewController()
    }

    func iaUnitControllerWillPresentFullscreen(_ unitController: IAUnitController?) {
        delegate?.providerWillPresent(self)
    }

    func iaAdWillLogImpression(_ unitController: IAUnitController?) {}

    func iaAdDidReceiveClick(_ unitController: IAUnitController?) {
        delegate?.providerDidClick(self)
    }

    func iaUnitControllerDidDismissFullscreen(_ unitController: IAUnitController?) {
        delegate?.providerDidHide(self)
    }

    func iaAdDidReward(_ unitController: IAUnitController?) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
}
