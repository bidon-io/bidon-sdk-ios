//
//  FullscreenImpressionController.swift
//  Bidon
//
//  Created by Bidon Team on 25.08.2022.
//

import Foundation
import UIKit


protocol FullscreenImpressionControllerDelegate: AnyObject {
    func willPresent(_ impression: inout Impression)

    func didHide(_ impression: inout Impression)

    func didClick(_ impression: inout Impression)

    func didExpire(_ impression: inout Impression)

    func didFailToPresent(_ impression: inout Impression?, error: SdkError)

    func didReceiveReward(_ reward: Reward, impression: inout Impression)
}


protocol FullscreenImpressionController: AnyObject {
    associatedtype BidType: Bid

    var impression: Impression { get set }

    init(bid: BidType)

    func show(from rootViewController: UIViewController)

    var delegate: FullscreenImpressionControllerDelegate? { get set }
}
