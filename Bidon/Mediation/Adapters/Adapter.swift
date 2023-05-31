//
//  AdapterProtocol.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 15.06.2022.
//

import Foundation


public protocol Adapter {
    var identifier: String { get }
    var name: String { get }
    var adapterVersion: String { get }
    var sdkVersion: String { get }
    
    init()
}


public protocol ParametersEncodableAdapter: Adapter {
    func encodeAdapterParameters(to encoder: Encoder) throws
}


public protocol InitializableAdapter: Adapter {
    func initialize(
        from decoder: Decoder,
        completion: @escaping (Result<Void, SdkError>) -> Void
    )
}


