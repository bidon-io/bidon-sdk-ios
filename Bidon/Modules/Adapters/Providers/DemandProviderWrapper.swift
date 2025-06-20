//
//  DemandProviderWrapper.swift
//  Bidon
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation


class DemandProviderWrapper<W>: NSObject, DemandProvider {
    var delegate: DemandProviderDelegate? {
        get { _delegate() }
        set { _setDelegate(newValue) }
    }

    var revenueDelegate: DemandProviderRevenueDelegate? {
        get { _revenueDelegate() }
        set { _setRevenueDelegate(newValue) }
    }

    func notify(ad: DemandAd, event: DemandProviderEvent) {
        _notify(ad, event)
    }

    let wrapped: W

    private let _delegate: () -> DemandProviderDelegate?
    private let _setDelegate: (DemandProviderDelegate?) -> ()

    private let _revenueDelegate: () -> DemandProviderRevenueDelegate?
    private let _setRevenueDelegate: (DemandProviderRevenueDelegate?) -> ()

    private let _notify: (DemandAd, DemandProviderEvent) -> ()

    init(_ wrapped: W) throws {
        self.wrapped = wrapped

        guard let wrapped = wrapped as? (any DemandProvider) else { throw SdkError.internalInconsistency }

        _delegate = { wrapped.delegate }
        _setDelegate = { wrapped.delegate = $0 }

        _revenueDelegate = { wrapped.revenueDelegate }
        _setRevenueDelegate = { wrapped.revenueDelegate = $0 }

        _notify = { wrapped.notify(opaque: $0, event: $1) }
    }
}
