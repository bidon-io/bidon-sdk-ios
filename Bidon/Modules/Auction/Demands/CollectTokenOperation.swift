//
//  CollectTokenOperation.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 24/06/2024.
//

import Foundation

final class CollectTokenOperation<AdTypeContextType: AdTypeContext>: AsynchronousOperation {
    typealias BuilderType = CollectTokenOperationBuilder<AdTypeContextType>
    
    let provider: any GenericBiddingDemandProvider
    let parameters: AdaptersInitialisationParameters.AdapterConfiguration
    let adapter: AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    
    var result: BiddingDemandToken?
    var isTimeoutReached = false
    
    var startTimestamp: TimeInterval?
    
    init(builder: BuilderType) {
        self.provider = builder.provider
        self.parameters = builder.configuration
        self.adapter = builder.adapter
    }
    
    override func main() {
        startTimestamp = Date.timestamp(.wall, units: .milliseconds)
                
        provider.collectBiddingTokenEncoder(adUnitExtrasDecoder: parameters.decoder) { [weak self] result in
            guard let self = self, !isTimeoutReached else { return }
            defer { self.finish() }
            
            let finishTimestamp = Date.timestamp(.wall, units: .milliseconds)
            switch result {
            case .success(let token):
                let demandToken = BiddingDemandToken(
                    demandId: adapter.demandId,
                    token: token,
                    tokenStartTs: startTimestamp?.uint,
                    tokenFinishTs: finishTimestamp.uint,
                    status: .success
                )
                
                self.result = demandToken
            case .failure:
                let demandToken = BiddingDemandToken(
                    demandId: adapter.demandId,
                    token: nil,
                    tokenStartTs: startTimestamp?.uint,
                    tokenFinishTs: finishTimestamp.uint,
                    status: .noToken
                )
                
                self.result = demandToken
            }
        }
    }
}

extension CollectTokenOperation: CollectTokenTimeoutHandler {
    func timeoutReached() {
        isTimeoutReached = true
        let finishTimestamp = Date.timestamp(.wall, units: .milliseconds)
        result = BiddingDemandToken(
            demandId: adapter.demandId,
            token: nil,
            tokenStartTs: startTimestamp?.uint ?? finishTimestamp.uint,
            tokenFinishTs: finishTimestamp.uint,
            status: .timeout
        )
        
        finish()
    }
}

final class CollectTokenOperationBuilder<AdTypeContextType: AdTypeContext> {

    var provider: (any GenericBiddingDemandProvider)!
    var configuration: AdaptersInitialisationParameters.AdapterConfiguration!
    var adapter: AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>!
    
    @discardableResult
    func withProwider(_ provider: any GenericBiddingDemandProvider) -> Self {
        self.provider = provider
        return self
    }
    
    @discardableResult
    func withConfiguration(_ configuration: AdaptersInitialisationParameters.AdapterConfiguration) -> Self {
        self.configuration = configuration
        return self
    }
    
    @discardableResult
    func withAdapter(_ adapter: AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>) -> Self {
        self.adapter = adapter
        return self
    }
}
