//
//  Permission.swift
//  Sandbox
//
//  Created by Bidon Team on 01.09.2022.
//

import Foundation
import Combine


enum PermissionState {
    case accepted
    case denied
    case notDetermined
}


protocol Permission {
    var name: String { get }
    var state: PermissionState { get }

    func request() async
}


extension Permission {
    func requestPublisher() -> AnyPublisher<Void, Never> {
        return Future<Void, Never> { promise in
            Task {
                await request()
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
}
