//
//  Reward.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 07.07.2022.
//

import Foundation


@objc(BDNReward)
public protocol Reward {
    var label: String { get }
    var amount: Int { get }
}


public final class RewardWrapper<Wrapped>: Reward {
    public let label: String
    public let amount: Int
    public let wrapped: Wrapped

    public init(
        label: String,
        amount: Int,
        wrapped: Wrapped
    ) {
        self.label = label
        self.amount = amount
        self.wrapped = wrapped
    }
}


public final class EmptyReward: Reward {
    public let label: String = ""
    public let amount: Int = .zero

    public init() {

    }
}
