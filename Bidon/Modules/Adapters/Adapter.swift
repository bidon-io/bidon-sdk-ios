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
    
    init()
}

// TODO: Decide to restore or remove it
//public protocol ParametersEncodableAdapter: Adapter {
//    func encodeAdapterParameters(to encoder: Encoder) throws
//}
