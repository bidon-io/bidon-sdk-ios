//
//  InitializableAdapter.swift
//  Bidon
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation


public protocol InitializableAdapter: Adapter {
    var isInitialized: Bool { get }
    
    func initialize(
        from decoder: Decoder,
        completion: @escaping (Result<Void, SdkError>) -> Void
    )
}

