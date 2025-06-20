//
//  EnvironmentRepository.swift
//  Bidon
//
//  Created by Bidon Team on 05.08.2022.
//

import Foundation


internal enum EnvironmentRepositoryKey: String {
    case app
    case geo
    case regulations
    case session
    case user
    case device
    case segment
    case extras
}


internal typealias EnvironmentRepository = Repository<EnvironmentRepositoryKey, Environment>


extension EnvironmentRepository {
    struct Parameters {
        var appKey: String
    }

    convenience init() {
        self.init("com.bidon.adapters-repository.queue")

        self[.app] = AppManager()
        self[.geo] = GeoManager()
        self[.regulations] = RegulationsManager()
        self[.session] = SessionManager()
        self[.user] = UserManager()
        self[.device] = DeviceManager()
        self[.segment] = SegmentManager()
        self[.extras] = ExtrasManager()
    }

    func configure(
        _ parameters: Parameters,
        completion: @escaping () -> ()
    ) {
        environment(AppManager.self).updateAppKey(parameters.appKey)

        guard environment(GeoManager.self).isAvailable else {
            completion()
            return
        }

        environment(GeoManager.self).prepare(completion: completion)
    }


    func environment<T: Environment>(_ type: T.Type) -> T {
        guard
            let key = EnvironmentRepositoryKey(type),
            let env: T = self[key]
        else { fatalError("Environment of type \(type) is not registered!") }

        return env
    }
}


private extension EnvironmentRepositoryKey {
    init?<T: Environment>(_ type: T.Type) {
        switch type {
        case is DeviceManager.Type: self = .device
        case is SessionManager.Type: self = .session
        case is AppManager.Type: self = .app
        case is UserManager.Type: self = .user
        case is GeoManager.Type: self = .geo
        case is RegulationsManager.Type: self = .regulations
        case is ExtrasManager.Type: self = .extras
        case is SegmentManager.Type: self = .segment
        default: return nil
        }
    }
}
