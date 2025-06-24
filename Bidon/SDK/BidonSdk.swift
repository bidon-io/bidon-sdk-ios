//
//  SDK.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 15.06.2022.
//

import Foundation
import UIKit

@objc(BDNSdk)
public final class BidonSdk: NSObject {
    enum InitializationState: String {
        case idle, initializing, initialized, failed
    }

    lazy var adaptersRepository = AdaptersRepository()
    lazy var environmentRepository = EnvironmentRepository()

    public private(set) var isTestMode: Bool = false

    @Injected(\.networkManager)
    private var networkManager: NetworkManager

    @objc public static let sdkVersion = Constants.sdkVersion

    @objc public static var isInitialized: Bool {
        shared.initializationState == .initialized
    }

    @objc public static var segment: Segment {
        shared.segment
    }

    @objc public static var regulations: Regulations {
        shared.regulations
    }

    private var initializationState = InitializationState.idle
    private var pendingCompletions: [() -> Void] = []

    private var isInitialized: Bool = false

    static let shared: BidonSdk = BidonSdk()

    private override init() {
        super.init()
    }

    @objc
    public static var logLevel: Logger.Level {
        get { Logger.level }
        set { Logger.level = newValue }
    }

    @objc
    public static var isTestMode: Bool {
        get { shared.isTestMode }
        set { shared.isTestMode = newValue }
    }

    @objc
    public static var baseURL: String {
        get { shared.networkManager.baseURL }
        set { shared.networkManager.baseURL = newValue }
    }

    @objc
    public static var HTTPHeaders: [String: String] {
        get { shared.networkManager.HTTPHeaders }
        set { shared.networkManager.HTTPHeaders = newValue }
    }

    @objc
    public static var extras: [String: AnyHashable]? {
        get {
            shared
                .environmentRepository
                .environment(ExtrasManager.self)
                .extras
        }
    }

    @objc
    public static func registerDefaultAdapters() {
        shared.adaptersRepository.configure()
    }

    @objc
    public static func registerAdapter(className: String) {
        shared.adaptersRepository.register(className: className)
    }

    public static func registeredAdapters() -> [Adapter] {
        return shared.adaptersRepository.all()
    }

    public static func registerAdapter(adapter: Adapter) {
        shared.adaptersRepository.register(adapter: adapter)
    }

    @objc
    public static func setExtraValue(
        _ value: AnyHashable?,
        for key: String
    ) {
        shared
            .environmentRepository
            .environment(ExtrasManager.self)
            .extras[key] = value
    }

    @objc
    public static func setFramework(
        _ framework: Framework,
        version: String
    ) {
        shared
            .environmentRepository
            .environment(AppManager.self)
            .updateFramework(framework, version: version)
    }

    @objc
    public static func setPluginVersion(
        _ pluginVersion: String
    ) {
        shared
            .environmentRepository
            .environment(AppManager.self)
            .updatePluginVersion(pluginVersion)
    }

    @objc
    public static func initialize(
        appKey: String,
        completion: @escaping () -> () = {}
    ) {
        switch shared.initializationState {
        case .idle, .failed:
            shared.pendingCompletions.append(completion)
            shared.initializationState = .initializing
            shared.initialize(appKey: appKey)

        case .initializing:
            Logger.warning("Bidon SDK is being initializing")

            shared.pendingCompletions.append(completion)

        case .initialized:
            Logger.warning("Bidon SDK has already been initialized")

            completion()
        }
    }

    static func addInitializationHandler(completion: @escaping () -> Void) {
        switch shared.initializationState {
        case .idle, .initializing:
            shared.pendingCompletions.append(completion)
        case .initialized, .failed:
            completion()
        }
    }

    private func initialize(
        appKey: String
    ) {
        let parameters = EnvironmentRepository.Parameters(appKey: appKey)

        environmentRepository.configure(parameters) { [unowned self] in
            let request = ConfigurationRequest { builder in
                builder.withAdaptersRepository(self.adaptersRepository)
                builder.withEnvironmentRepository(self.environmentRepository)
                builder.withTestMode(self.isTestMode)
                builder.withExt(BidonSdk.extras ?? [:])
            }

            self.networkManager.perform(request: request) { [unowned self] result in
                switch result {
                case .success(let response):
                    ConfigParametersStorage.store(response.adaptersInitializationParameters)
                    ConfigParametersStorage.store(response.bidding.tokenTimeoutMs)

                    AdaptersInitializator(
                        parameters: response.adaptersInitializationParameters,
                        repository: self.adaptersRepository
                    )
                    .initialize { [unowned self] in
                        self.initializationState = .initialized
                        self.flushPendingCompletions()
                    }

                case .failure(let error):
                    Logger.error("Network error while initializing Bidon SDK: \(error)")
                    DispatchQueue.main.async {
                        self.initializationState = .failed
                        self.flushPendingCompletions()
                    }
                }
            }
        }
    }

    func updateSegmentIfNeeded(_ segment: SegmentResponse?) {
        guard let segment = segment else { return }
        environmentRepository.environment(SegmentManager.self).uid = segment.uid
    }

    private func flushPendingCompletions() {
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        completions.forEach { $0() }
    }
}
