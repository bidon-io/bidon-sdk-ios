//
//  ProgrammaticDemandProviderMock.swift
//  Tests-Swift
//
//  Created by Bidon Team on 22.06.2023.
//

import Foundation
import XCTest


@testable import Bidon


protocol DemandProviderMockBuilder {}


protocol DemandProviderMockBuildable: DemandProviderMock {
    associatedtype Builder: DemandProviderMockBuilder

    init(build: (Builder) -> ())
}


class DemandProviderMock: DemandProvider {
    typealias DemandAdType = DemandAdMock

    var invokedDelegateSetter = false
    var invokedDelegateSetterCount = 0
    var invokedDelegate: DemandProviderDelegate?
    var invokedDelegateList = [DemandProviderDelegate?]()
    var invokedDelegateGetter = false
    var invokedDelegateGetterCount = 0
    var stubbedDelegate: DemandProviderDelegate!

    var delegate: DemandProviderDelegate? {
        set {
            invokedDelegateSetter = true
            invokedDelegateSetterCount += 1
            invokedDelegate = newValue
            invokedDelegateList.append(newValue)
        }
        get {
            invokedDelegateGetter = true
            invokedDelegateGetterCount += 1
            return stubbedDelegate
        }
    }

    var invokedRevenueDelegateSetter = false
    var invokedRevenueDelegateSetterCount = 0
    var invokedRevenueDelegate: DemandProviderRevenueDelegate?
    var invokedRevenueDelegateList = [DemandProviderRevenueDelegate?]()
    var invokedRevenueDelegateGetter = false
    var invokedRevenueDelegateGetterCount = 0
    var stubbedRevenueDelegate: DemandProviderRevenueDelegate!

    var revenueDelegate: DemandProviderRevenueDelegate? {
        set {
            invokedRevenueDelegateSetter = true
            invokedRevenueDelegateSetterCount += 1
            invokedRevenueDelegate = newValue
            invokedRevenueDelegateList.append(newValue)
        }
        get {
            invokedRevenueDelegateGetter = true
            invokedRevenueDelegateGetterCount += 1
            return stubbedRevenueDelegate
        }
    }

    var invokedNotify = false
    var invokedNotifyCount = 0
    var invokedNotifyParameters: (ad: DemandAdType, event: DemandProviderEvent)?
    var invokedNotifyParametersList = [(ad: DemandAdType, event: DemandProviderEvent)]()
    var stubbedNotify: ((DemandAdType, DemandProviderEvent) -> ())?

    func notify(ad: DemandAdType, event: DemandProviderEvent) {
        invokedNotify = true
        invokedNotifyCount += 1
        invokedNotifyParameters = (ad, event)
        invokedNotifyParametersList.append((ad, event))
        stubbedNotify?(ad, event)
    }
}
