//
//  CollectTokenTimeoutOperation.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 24/06/2024.
//

import Foundation

protocol CollectTokenTimeoutHandler: Operation {
    func timeoutReached()
}

final class CollectTokenTimeoutOperation<AdTypeContextType: AdTypeContext>: AsynchronousOperation {
    private var timer: Timer?
    
    let interval: TimeInterval
    private var operations = NSHashTable<Operation>.weakObjects()
    
    init(interval: TimeInterval) {
        self.interval = interval
        
        super.init()
    }
    
    func invalidate() {
        timer?.invalidate()
        finish()
    }
    
    func add(_ operation: CollectTokenOperation<AdTypeContextType>?) {
        guard let operation else { return }
        operations.add(operation)
    }

    override func main() {
        super.main()
                
        guard interval > 0 else {
            finish()
            return
        }
        
        let timer = Timer(
            timeInterval: interval,
            repeats: false
        ) { [weak self] _ in
            guard let self = self, self.isExecuting else { return }
            self.operations
                .allObjects
                .compactMap { $0 as? CollectTokenTimeoutHandler }
                .forEach { $0.timeoutReached() }
            self.finish()
        }
        
        RunLoop.main.add(timer, forMode: .default)
        self.timer = timer
    }
}
