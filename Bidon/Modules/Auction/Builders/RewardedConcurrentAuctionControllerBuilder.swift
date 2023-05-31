//
//  RewardedConcurrentAuctionControllerBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 11.08.2022.
//

import Foundation


final class RewardedConcurrentAuctionControllerBuilder: BaseConcurrentAuctionControllerBuilder<AnyRewardedAdDemandProvider> {
    override func adapters() -> [AnyDemandSourceAdapter<AnyRewardedAdDemandProvider>] {
        return directDemandWrappedAdapters() +
        biddingDemandWrappedAdapters() +
        programmaticDemandWrappedAdapters()
    }
    
    private func directDemandWrappedAdapters() -> [AnyDemandSourceAdapter<AnyRewardedAdDemandProvider>] {
        let direct: [DirectRewardedAdDemandSourceAdapter] = adaptersRepository.all()
        
        return direct.compactMap { adapter in
            do {
                let provider = try adapter.directRewardedAdDemandProvider()
                let wrappedProvider: AnyRewardedAdDemandProvider = try DirectDemandProviderWrapper(provider)
                
                return AnyDemandSourceAdapter(
                    adapter: adapter,
                    provider: wrappedProvider
                )
            } catch {
                Logger.warning("Unable to create rewarded ad demand provider for \(adapter), error: \(error)")
                return nil
            }
        }
    }
    
    private func programmaticDemandWrappedAdapters() -> [AnyDemandSourceAdapter<AnyRewardedAdDemandProvider>] {
        let programmatic: [ProgrammaticRewardedAdDemandSourceAdapter] = adaptersRepository.all()
        return programmatic.compactMap { adapter in
            do {
                let provider = try adapter.programmaticRewardedAdDemandProvider()
                let wrappedProvider: AnyRewardedAdDemandProvider = try ProgrammaticDemandProviderWrapper(provider)
                
                return AnyDemandSourceAdapter(
                    adapter: adapter,
                    provider: wrappedProvider
                )
            } catch {
                Logger.warning("Unable to create rewarded ad demand provider for \(adapter), error: \(error)")
                return nil
            }
        }
    }
    
    private func biddingDemandWrappedAdapters() -> [AnyDemandSourceAdapter<AnyRewardedAdDemandProvider>] {
        let bidding: [BiddingRewardedAdDemandSourceAdapter] = adaptersRepository.all()
        return bidding.compactMap { adapter in
            do {
                let provider = try adapter.biddingRewardedAdDemandProvider()
                let wrappedProvider: AnyRewardedAdDemandProvider = try BiddingDemandProviderWrapper(provider)
                
                return AnyDemandSourceAdapter(
                    adapter: adapter,
                    provider: wrappedProvider
                )
            } catch {
                Logger.warning("Unable to create rewarded ad demand provider for \(adapter), error: \(error)")
                return nil
            }
        }
    }
}
