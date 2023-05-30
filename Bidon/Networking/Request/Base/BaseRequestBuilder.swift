//
//  BaseRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 11.08.2022.
//

import Foundation


class BaseRequestBuilder {
    private(set) var adaptersRepository: AdaptersRepository!
    private(set) var testMode: Bool = false
    
    private var ext: [String: Any]?
    private var environmentRepository: EnvironmentRepository!
    
    private var geo: GeoModel? {
        guard
            let manager = environmentRepository.environment(GeoManager.self),
            manager.isAvailable
        else { return nil }

        return GeoModel(manager)
    }
    
    var device: DeviceModel? {
        let manager = environmentRepository.environment(DeviceManager.self)
        return manager.map { DeviceModel($0, geo: geo) }
    }
    
    var session: SessionModel? {
        let manager = environmentRepository.environment(SessionManager.self)
        return manager.map { SessionModel($0) }
    }
    
    var app: AppModel? {
        let manager = environmentRepository.environment(AppManager.self)
        return manager.map { AppModel($0) }
    }
    
    var user: UserModel? {
        let manager = environmentRepository.environment(UserManager.self)
        return manager.map { UserModel($0) }
    }
    
    var regulations: RegulationsModel? {
        let manager = environmentRepository.environment(RegulationsManager.self)
        return manager.map { RegulationsModel($0) }
    }
    
    var encodedExt: String? {
        ext
            .flatMap { try? JSONSerialization.data(withJSONObject: $0, options: []) }
            .flatMap { String(data: $0, encoding: .utf8) }
    }
    
    @discardableResult
    func withAdaptersRepository(_ adaptersRepository: AdaptersRepository) -> Self {
        self.adaptersRepository = adaptersRepository
        return self
    }
    
    @discardableResult
    func withEnvironmentRepository(_ environmentRepository: EnvironmentRepository?) -> Self {
        self.environmentRepository = environmentRepository
        return self
    }
    
    @discardableResult
    func withExt(_ ext: [String: Any] ...) -> Self {
        self.ext = ext.reduce([:]) { result, next in
            result.merging(next) { current, _ in current }
        }
        return self
    }
    
    @discardableResult
    func withTestMode(_ testMode: Bool) -> Self {
        self.testMode = testMode
        return self
    }
    
}
