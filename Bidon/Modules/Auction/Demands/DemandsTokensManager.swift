//
//  DemandsTokensManager.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 24/05/2024.
//

import Foundation

final class DemandsTokensManager<AdTypeContextType: AdTypeContext> {
    
    typealias DemandProviderType = AdTypeContextType.DemandProviderType
    typealias BidType = BidModel<DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    typealias BuilderType = DemandsTokensManagerBuilder<AdTypeContextType>

    private var adapters: [AdapterType]
    private let demands: [String]
    private let timeout: TimeInterval
    
    var tokens = [BiddingDemandToken]()
    
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "io.bidon.tokensQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .default
        return queue
    }()
    
    private lazy var timerQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "io.bidon.timerQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .default
        return queue
    }()
    
    init(builder: BuilderType) {
        self.adapters = builder.adapters
        self.demands = builder.demands
        self.timeout = builder.timeout / 1000
    }
    
    func load(initializationParameters: AdaptersInitialisationParameters, completion: @escaping ((Result<[BiddingDemandToken], Error>) -> Void)) {
        var operations = [Operation]()
        for demandId in demands {
            guard
                let adapter = adapters.first(where: { $0.demandId == demandId && $0.provider is any GenericBiddingDemandProvider }),
                let provider = adapter.provider as? any GenericBiddingDemandProvider,
                let parameters = initializationParameters.adapters.first(where: { $0.demandId == adapter.demandId })
            else {
                continue
            }
                        
            let builder = CollectTokenOperationBuilder<AdTypeContextType>()
            builder.adapter = adapter
            builder.configuration = parameters
            builder.provider = provider
            
            let operation = CollectTokenOperation(builder: builder)
            let postCollectOperation = BlockOperation { [weak self, weak operation] in
                if let result = operation?.result, operation?.isCancelled == false {
                    self?.tokens.append(result)
                }
            }
            postCollectOperation.addDependency(operation)
            
            operations.append(operation)
            operations.append(postCollectOperation)
        }
        
        // post collect all tokens operation
        let postOperation = BlockOperation { [weak self] in
            guard let self else { return }
            completion(.success(self.tokens))
        }
        if let last = operations.last {
            postOperation.addDependency(last)
        }
        
        // timeout
        let timeoutOperation = CollectTokenTimeoutOperation<AdTypeContextType>(interval: timeout)
        operations.forEach({ timeoutOperation.add($0 as? CollectTokenOperation<AdTypeContextType>) })
        
        timerQueue.addOperation(timeoutOperation)
        operations.forEach({ operationQueue.addOperation($0) })
        operationQueue.addOperation(postOperation)
    }
}
