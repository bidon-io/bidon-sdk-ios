//
//  InterstitialAdaptersFetcher.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 27/05/2024.
//

import Foundation

final class InterstitialAdaptersFetcher: AdaptersFetcher<InterstitialAdTypeContext> {
    
    private let adaptersRepository = BidonSdk.shared.adaptersRepository
    
    override func adapters() -> [AnyDemandSourceAdapter<AnyInterstitialDemandProvider>] {
        return directDemandWrappedAdapters() + biddingDemandWrappedAdapters()
    }
    
    private func directDemandWrappedAdapters() -> [AnyDemandSourceAdapter<AnyInterstitialDemandProvider>] {
        let direct: [DirectInterstitialDemandSourceAdapter] = adaptersRepository.all()
        
        return direct.compactMap { adapter in
            do {
                let provider = try adapter.directInterstitialDemandProvider()
                let wrappedProvider: AnyInterstitialDemandProvider = try DirectDemandProviderWrapper(provider)
                
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
    
    private func biddingDemandWrappedAdapters() -> [AnyDemandSourceAdapter<AnyInterstitialDemandProvider>] {
        let bidding: [BiddingInterstitialDemandSourceAdapter] = adaptersRepository.all()
        return bidding.compactMap { adapter in
            do {
                let provider = try adapter.biddingInterstitialDemandProvider()
                let wrappedProvider: AnyInterstitialDemandProvider = try BiddingDemandProviderWrapper(provider)
                
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
