//
//  AdViewConcurrentAuctionControllerBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 11.08.2022.
//

import Foundation


final class AdViewConcurrentAuctionControllerBuilder: BaseConcurrentAuctionControllerBuilder<AnyAdViewDemandProvider> {
    private var context: AdViewContext!
    
    @discardableResult
    public func withContext(_ context: AdViewContext) -> Self {
        self.context = context
        return self
    }
    
    override func adapters() -> [AnyDemandSourceAdapter<AnyAdViewDemandProvider>] {
        return directDemandWrappedAdapters() +
        biddingDemandWrappedAdapters() +
        programmaticDemandWrappedAdapters()
    }
    
    private func directDemandWrappedAdapters() -> [AnyDemandSourceAdapter<AnyAdViewDemandProvider>] {
        let direct: [DirectAdViewDemandSourceAdapter] = adaptersRepository.all()
        
        return direct.compactMap { adapter in
            do {
                let provider = try adapter.directAdViewDemandProvider(context: context)
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
    
    private func programmaticDemandWrappedAdapters() -> [AnyDemandSourceAdapter<AnyAdViewDemandProvider>] {
        let programmatic: [ProgrammaticAdViewDemandSourceAdapter] = adaptersRepository.all()
        return programmatic.compactMap { adapter in
            do {
                let provider = try adapter.programmaticAdViewDemandProvider(context: context)
                let wrappedProvider: AnyAdViewDemandProvider = try ProgrammaticDemandProviderWrapper(provider)
                
                return AnyDemandSourceAdapter(
                    adapter: adapter,
                    provider: wrappedProvider
                )
            } catch {
                Logger.warning("Unable to ad view demand provider for \(adapter), error: \(error)")
                return nil
            }
        }
    }
    
    private func biddingDemandWrappedAdapters() -> [AnyDemandSourceAdapter<AnyAdViewDemandProvider>] {
        let bidding: [BiddingAdViewDemandSourceAdapter] = adaptersRepository.all()
        return bidding.compactMap { adapter in
            do {
                let provider = try adapter.biddingAdViewDemandProvider(context: context)
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
