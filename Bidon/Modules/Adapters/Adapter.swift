//
//  AdapterProtocol.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 15.06.2022.
//

import Foundation


public protocol Adapter {
    var demandId: String { get }
    var name: String { get }
    var adapterVersion: String { get }
    var sdkVersion: String { get }
    var fullAdapterVersion: String { get }

    init()
}

extension Adapter {
    public var fullAdapterVersion: String {
        return sdkVersion + "." + adapterVersion
    }
}

// TODO: Decide to restore or remove it
//public protocol ParametersEncodableAdapter: Adapter {
//    func encodeAdapterParameters(to encoder: Encoder) throws
//}
