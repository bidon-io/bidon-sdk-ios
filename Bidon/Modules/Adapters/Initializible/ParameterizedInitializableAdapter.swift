//
//  ParameterizedInitializableAdapter.swift
//  Bidon
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation


public protocol ParameterizedInitializableAdapter: InitializableAdapter {
    associatedtype Parameters: Decodable

    func initialize(
        parameters: Parameters,
        completion: @escaping (SdkError?) -> Void
    )
}


extension ParameterizedInitializableAdapter {
    public func initialize(
        from decoder: Decoder,
        completion: @escaping (Result<Void, SdkError>) -> Void
    ) {
        var parameters: Parameters?

        do {
            parameters = try Parameters(from: decoder)
        } catch {
            completion(.failure(SdkError(error)))
        }

        guard let parameters = parameters else { return }

        initialize(parameters: parameters) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
