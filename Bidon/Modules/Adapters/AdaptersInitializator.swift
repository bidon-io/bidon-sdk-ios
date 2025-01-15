//
//  AdaptersInitializator.swift
//  Bidon
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation


struct AdaptersInitializator {
    private class InitializeAdapterTimeoutGuardOperation: AsynchronousOperation {
        let timeout: TimeInterval
        let adapter: InitializableAdapter
        let config: AdaptersInitialisationParameters.AdapterConfiguration
        
        var timestamp: TimeInterval = 0
        var timer: Timer?
        
        init(
            timeout: TimeInterval,
            adapter: InitializableAdapter,
            config: AdaptersInitialisationParameters.AdapterConfiguration
        ) {
            self.timeout = timeout
            self.adapter = adapter
            self.config = config
        }
        
        override func main() {
            super.main()
            
            Logger.info("Initialize \(adapter.name) ad network, order: \(config.order)")

            if timeout > 0 {
                let timeout = Date.MeasurementUnits.milliseconds.convert(
                    timeout,
                    to: .seconds
                )
                
                let timer = Timer(
                    timeInterval: timeout,
                    repeats: true
                ) { [weak self] timer in
                    guard let self = self, self.isExecuting else { return }
                    Logger.warning("\(self.adapter.name) adapter has reached timeout \(timeout)s during initialization")
                    self.finish()
                }
                
                RunLoop.main.add(timer, forMode: .default)
                self.timer = timer
            }
            
            timestamp = Date.timestamp(.wall, units: .seconds)
            
            DispatchQueue.main.async { [unowned self] in
                self.adapter.initialize(from: config.decoder) { [weak self] result in
                    defer { self?.finish() }
                    guard let self = self, self.isExecuting else { return }
                    
                    let time = round(Date.timestamp(.wall, units: .seconds) - self.timestamp)
                    
                    self.timer?.invalidate()
                    
                    switch result {
                    case .success:
                        Logger.info("\(self.adapter.name) adapter was initilized in \(time)s")
                    case .failure(let error):
                        Logger.warning("\(self.adapter.name) adapter returned initialization error \(error) in \(time)s")
                    }
                }
            }
        }
    }
    
    var parameters: AdaptersInitialisationParameters
    var respoitory: AdaptersRepository
    
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.bidon.initialization.queue"
        queue.qualityOfService = .default
        return queue
    }()
    
    private var operations: [InitializeAdapterTimeoutGuardOperation] {
        parameters.adapters.compactMap { config in
            guard
                let adapter: InitializableAdapter = respoitory[config.demandId],
                !adapter.isInitialized
            else { return nil }
            
            return InitializeAdapterTimeoutGuardOperation(
                timeout: parameters.tmax,
                adapter: adapter,
                config: config
            )
        }
    }
    
    init(
        parameters: AdaptersInitialisationParameters,
        respoitory: AdaptersRepository
    ) {
        self.parameters = parameters
        self.respoitory = respoitory
    }
    
    func initialize(completion: @escaping () -> ()) {
        guard !parameters.adapters.isEmpty else {
            completion()
            return
        }
        let timestamp = Date.timestamp(.wall, units: .seconds)
        Logger.info("Initialize ad networks")
        
        let completionOperation = BlockOperation {
            Logger.info("Finish initialize ad networks in \(round(Date.timestamp(.wall, units: .seconds) - timestamp))s")
            DispatchQueue.main.async {
                completion()
            }
        }
        
        var graph = DirectedAcyclicGraph<Operation>()
        
        let operations = self.operations
        
        try? graph.add(node: completionOperation)
        operations.forEach {
            try? graph.add(node: $0)
            try? graph.addEdge(from: $0, to: completionOperation)
        }
        
        let count = operations.map { $0.config.order }.max() ?? 0
        
        if count > 0 {
            for order in 1...count {
                for parent in operations where parent.config.order == order - 1 {
                    for children in operations where children.config.order == order {
                        try? graph.addEdge(from: parent, to: children)
                    }
                }
            }
        }
        
        queue.maxConcurrentOperationCount = parameters.adapters.count
        queue.addOperations(
            graph.operations(),
            waitUntilFinished: false
        )
    }
}
