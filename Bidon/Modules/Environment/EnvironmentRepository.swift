//
//  EnvironmentRepository.swift
//  Bidon
//
//  Created by Bidon Team on 05.08.2022.
//

import Foundation


internal typealias EnvironmentRepository = Repository<EnvironmentRepositoryKey, EnvironmentManager>


enum EnvironmentRepositoryKey: String {
    case app
    case geo
    case regulations
    case session
    case user
    case device
}


extension EnvironmentRepository {
    struct Parameters {
        struct FrameworkInfo {
            var framework: Framework = .native
            var frameworkVersion: String?
            var pluginVersion: String?
        }
        
        var appKey: String
        var framework: FrameworkInfo
    }
    
    convenience init() {
        self.init("com.bidon.adapters-repository.queue")
    }
    
    func configure(
        _ parameters: Parameters,
        completion: @escaping () -> ()
    ) {
        self[.device] = DeviceManager()
        self[.session] = SessionManager()
        self[.regulations] = RegulationsManager()
        self[.app] = AppManager(
            key: parameters.appKey,
            framework: parameters.framework.framework,
            frameworkVersion: parameters.framework.frameworkVersion,
            pluginVersion: parameters.framework.pluginVersion
        )
        self[.user] = UserManager()
        
        let geo = GeoManager()
        self[.geo] = geo
        
        guard geo.isAvailable else {
            completion()
            return
        }
        
        geo.prepare(completion: completion)
    }
    
    
    func environment<T: EnvironmentManager>(_ type: T.Type) -> T? {
        guard let key = EnvironmentRepositoryKey(type) else { return nil }
        let env: T? = self[key]
        return env
    }
}


extension EnvironmentRepositoryKey {
    init?<T: EnvironmentManager>(_ type: T.Type) {
        switch type {
        case is DeviceManager.Type: self = .device
        case is SessionManager.Type: self = .session
        case is AppManager.Type: self = .app
        case is UserManager.Type: self = .user
        case is GeoManager.Type: self = .geo
        case is RegulationsManager.Type: self = .regulations
        default: return nil
        }
    }
}



