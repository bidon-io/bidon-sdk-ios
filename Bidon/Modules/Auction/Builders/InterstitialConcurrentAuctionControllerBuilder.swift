//
//  InterstitialConcurrentAuctionControllerBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 11.08.2022.
//

import Foundation


final class InterstitialConcurrentAuctionControllerBuilder: BaseConcurrentAuctionControllerBuilder<InterstitialAdTypeContext> {
    override func adapters() -> [AnyDemandSourceAdapter<AnyInterstitialDemandProvider>] {
        return directDemandWrappedAdapters() +
        biddingDemandWrappedAdapters() +
        programmaticDemandWrappedAdapters()
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
    
    private func programmaticDemandWrappedAdapters() -> [AnyDemandSourceAdapter<AnyInterstitialDemandProvider>] {
        let programmatic: [ProgrammaticInterstitialDemandSourceAdapter] = adaptersRepository.all()
        return programmatic.compactMap { adapter in
            do {
                let provider = try adapter.programmaticInterstitialDemandProvider()
                let wrappedProvider: AnyInterstitialDemandProvider = try ProgrammaticDemandProviderWrapper(provider)
                
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

