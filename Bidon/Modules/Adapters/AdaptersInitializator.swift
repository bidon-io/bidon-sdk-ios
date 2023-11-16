//
//  AdaptersInitializator.swift
//  Bidon
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation


struct AdaptersInitializator {
    private class TimeoutGuard {
        let timeout: TimeInterval
        let adapter: InitializableAdapter
        let decoder: Decoder
        
        var timestamp: TimeInterval = 0
        var timer: Timer?
        
        init(
            timeout: TimeInterval,
            adapter: InitializableAdapter,
            decoder: Decoder
        ) {
            self.timeout = timeout
            self.adapter = adapter
            self.decoder = decoder
        }
        
        func initialize(completion: @escaping () -> ()) {
            if timeout > 0 {
                let timeout = Date.MeasurementUnits.milliseconds.convert(
                    timeout,
                    to: .seconds
                )
                
                let timer = Timer(
                    timeInterval: timeout,
                    repeats: true
                ) { [weak self] timer in
                    guard let self = self else { return }
                    Logger.warning("\(self.adapter.name) adapter has reached timeout \(timeout)s during initialization")
                    completion()
                }
                
                RunLoop.main.add(timer, forMode: .default)
                self.timer = timer
            }
            
            timestamp = Date.timestamp(.wall, units: .seconds)
            
            adapter.initialize(from: decoder) { [weak self] result in
                guard let self = self else { return }
            
                defer { DispatchQueue.global().async(execute:completion) }
                
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
    
    var parameters: AdaptersInitialisationParameters
    var respoitory: AdaptersRepository
    
    private var disposeBag = NSHashTable<TimeoutGuard>(options: .strongMemory)
    
    init(
        parameters: AdaptersInitialisationParameters,
        respoitory: AdaptersRepository
    ) {
        self.parameters = parameters
        self.respoitory = respoitory
    }
    
    func initialize(completion: @escaping () -> ()) {
        let group = DispatchGroup()
        
        for (demandId, decoder) in parameters.adapters {
            guard
                let adapter: InitializableAdapter = respoitory[demandId],
                !adapter.isInitialized
            else { continue }
            group.enter()

            let initializator = TimeoutGuard(
                timeout: parameters.tmax,
                adapter: adapter,
                decoder: decoder
            )
            
            disposeBag.add(initializator)
            
            initializator.initialize { [weak initializator] in
                disposeBag.remove(initializator)
                group.leave()
            }
        }
        
        group.notify(
            queue: .main,
            execute: completion
        )
    }
}
