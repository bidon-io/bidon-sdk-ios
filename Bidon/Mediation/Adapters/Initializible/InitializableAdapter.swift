//
//  InitializableAdapter.swift
//  Bidon
//
//  Created by Stas Kochkin on 13.07.2023.
//

import Foundation


public protocol InitializableAdapter: Adapter {
    func initialize(
        from decoder: Decoder,
        completion: @escaping (Result<Void, SdkError>) -> Void
    )
}

