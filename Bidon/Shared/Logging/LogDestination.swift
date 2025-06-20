//
//  LogDestination.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 20.07.2022.
//

import Foundation


protocol LogDestination {
    var id: String { get }

    func send(level: Logger.Level, _ message: String)
}


struct AnyLogDestination: LogDestination, Hashable {
    private let _id: () -> String
    private let _send: (Logger.Level, String) -> ()

    var id: String { _id() }

    static func == (lhs: AnyLogDestination, rhs: AnyLogDestination) -> Bool {
        return lhs.id == rhs.id
    }

    init(_ destination: LogDestination) {
        self._send = { destination.send(level: $0, $1) }
        self._id = { destination.id }
    }

    func send(level: Logger.Level, _ message: String) {
        _send(level, message)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
