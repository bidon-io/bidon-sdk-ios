//
//  AsynchronousOperation.swift
//  Bidon
//
//  Created by Bidon Team on 20.04.2023.
//

import Foundation


internal class AsynchronousOperation: Operation {
    enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        fileprivate var keyPath: String { return "is" + self.rawValue }
    }

    @Atomic
    private var _state: State = .ready

    override var isAsynchronous: Bool {
        return true
    }

    override var isExecuting: Bool {
        return state == .executing
    }

    override var isFinished: Bool {
        return state == .finished
    }

    final override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }

    open override func main() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .executing
        }
    }

    final func finish() {
        state = .finished
    }

    /// Thread-safe computed state value
    var state: State {
        get { _state }
        set {
            let oldValue = state
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
            $_state.wrappedValue = newValue
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
}
