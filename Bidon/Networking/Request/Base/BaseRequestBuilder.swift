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

    var device: DeviceModel {
        let manager = environmentRepository.environment(DeviceManager.self)
        return DeviceModel(manager, geo: geo)
    }

    private var geo: GeoModel? {
        let manager = environmentRepository.environment(GeoManager.self)
        guard manager.isAvailable else { return nil }

        return GeoModel(manager)
    }

    var session: SessionModel {
        let manager = environmentRepository.environment(SessionManager.self)
        return SessionModel(manager)
    }

    var app: AppModel {
        let manager = environmentRepository.environment(AppManager.self)
        return AppModel(manager)
    }

    var user: UserModel {
        let manager = environmentRepository.environment(UserManager.self)
        return UserModel(manager)
    }

    var regulations: RegulationsModel {
        let manager = environmentRepository.environment(RegulationsManager.self)
        return RegulationsModel(manager)
    }

    var segment: SegmentModel {
        let manager = environmentRepository.environment(SegmentManager.self)
        return SegmentModel(manager)
    }

    var encodedExt: String? {
        let sdkExtras: [String: Any] = environmentRepository
            .environment(ExtrasManager.self)
            .extras

        let extras: [String: Any] = ext.map { ext in
            ext.merging(sdkExtras) { current, _ in
                return current
            }
        } ?? sdkExtras

        return (
            try? JSONSerialization.data(withJSONObject: extras, options: [])
        )
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
