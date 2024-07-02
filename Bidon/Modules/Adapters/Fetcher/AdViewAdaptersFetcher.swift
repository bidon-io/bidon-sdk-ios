//
//  AdViewAdaptersFetcher.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 27/05/2024.
//

import Foundation

final class AdViewAdaptersFetcher: AdaptersFetcher<BannerAdTypeContext> {
    private var viewContext: AdViewContext!
    
    @discardableResult
    public func withViewContext(_ viewContext: AdViewContext) -> Self {
        self.viewContext = viewContext
        return self
    }
    
    private let adaptersRepository = BidonSdk.shared.adaptersRepository
    
    override func adapters() -> [AnyDemandSourceAdapter<AnyAdViewDemandProvider>] {
        return directDemandWrappedAdapters() +
        biddingDemandWrappedAdapters()
    }
    
    private func directDemandWrappedAdapters() -> [AnyDemandSourceAdapter<AnyAdViewDemandProvider>] {
        let direct: [DirectAdViewDemandSourceAdapter] = adaptersRepository.all()
        
        return direct.compactMap { adapter in
            do {
                let provider = try adapter.directAdViewDemandProvider(context: viewContext)
                let wrappedProvider: AnyAdViewDemandProvider = try DirectDemandProviderWrapper(provider)
                
                return AnyDemandSourceAdapter(
                    adapter: adapter,
                    provider: wrappedProvider
                )
            } catch {
                Logger.warning("Unable to create ad view demand provider for \(adapter), error: \(error)")
                return nil
            }
        }
    }
    
    private func biddingDemandWrappedAdapters() -> [AnyDemandSourceAdapter<AnyAdViewDemandProvider>] {
        let bidding: [BiddingAdViewDemandSourceAdapter] = adaptersRepository.all()
        return bidding.compactMap { adapter in
            do {
                let provider = try adapter.biddingAdViewDemandProvider(context: viewContext)
                let wrappedProvider: AnyAdViewDemandProvider = try BiddingDemandProviderWrapper(provider)
                
                return AnyDemandSourceAdapter(
                    adapter: adapter,
                    provider: wrappedProvider
                )
            } catch {
                Logger.warning("Unable to create interstitial demand provider for \(adapter), error: \(error)")
                return nil
            }
        }
    }
}
