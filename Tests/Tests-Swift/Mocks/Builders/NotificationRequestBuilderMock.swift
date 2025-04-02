//
//  LossRequestBuilderMock.swift
//  Tests-Swift
//
//  Created by Bidon Team on 22.06.2023.
//

import Foundation

@testable import Bidon


final class NotificationRequestBuilderMock: BaseRequestBuilder, NotificationRequestBuilder {
    typealias Context = AdTypeContextMock
    
    var invokedAdaptersRepositoryGetter = false
    var invokedAdaptersRepositoryGetterCount = 0
    var stubbedAdaptersRepository: AdaptersRepository!

    override var adaptersRepository: AdaptersRepository! {
        invokedAdaptersRepositoryGetter = true
        invokedAdaptersRepositoryGetterCount += 1
        return stubbedAdaptersRepository
    }

    var invokedTestModeGetter = false
    var invokedTestModeGetterCount = 0
    var stubbedTestMode: Bool! = false

    override var testMode: Bool {
        invokedTestModeGetter = true
        invokedTestModeGetterCount += 1
        return stubbedTestMode
    }

    var invokedDeviceGetter = false
    var invokedDeviceGetterCount = 0
    var stubbedDevice: DeviceModel!

    override var device: DeviceModel {
        invokedDeviceGetter = true
        invokedDeviceGetterCount += 1
        return stubbedDevice
    }

    var invokedSessionGetter = false
    var invokedSessionGetterCount = 0
    var stubbedSession: SessionModel!

    override var session: SessionModel {
        invokedSessionGetter = true
        invokedSessionGetterCount += 1
        return stubbedSession
    }

    var invokedAppGetter = false
    var invokedAppGetterCount = 0
    var stubbedApp: AppModel!

    override var app: AppModel {
        invokedAppGetter = true
        invokedAppGetterCount += 1
        return stubbedApp
    }

    var invokedUserGetter = false
    var invokedUserGetterCount = 0
    var stubbedUser: UserModel!

    override var user: UserModel {
        invokedUserGetter = true
        invokedUserGetterCount += 1
        return stubbedUser
    }

    var invokedRegulationsGetter = false
    var invokedRegulationsGetterCount = 0
    var stubbedRegulations: RegulationsModel!

    override var regulations: RegulationsModel {
        invokedRegulationsGetter = true
        invokedRegulationsGetterCount += 1
        return stubbedRegulations
    }

    var invokedSegmentGetter = false
    var invokedSegmentGetterCount = 0
    var stubbedSegment: SegmentModel!

    override var segment: SegmentModel {
        invokedSegmentGetter = true
        invokedSegmentGetterCount += 1
        return stubbedSegment
    }

    var invokedEncodedExtGetter = false
    var invokedEncodedExtGetterCount = 0
    var stubbedEncodedExt: String!

    override var encodedExt: String? {
        invokedEncodedExtGetter = true
        invokedEncodedExtGetterCount += 1
        return stubbedEncodedExt
    }

    var invokedImpGetter = false
    var invokedImpGetterCount = 0
    var stubbedImp: ImpressionModel!

    var imp: ImpressionModel {
        invokedImpGetter = true
        invokedImpGetterCount += 1
        return stubbedImp
    }

    var invokedExternalWinnerGetter = false
    var invokedExternalWinnerGetterCount = 0
    var stubbedExternalWinner: NotificationRequest.ExternalWinner!

    var externalWinner: NotificationRequest.ExternalWinner? {
        invokedExternalWinnerGetter = true
        invokedExternalWinnerGetterCount += 1
        return stubbedExternalWinner
    }

    var invokedRouteGetter = false
    var invokedRouteGetterCount = 0
    var stubbedRoute: Route!

    var route: Route {
        invokedRouteGetter = true
        invokedRouteGetterCount += 1
        return stubbedRoute
    }

    var invokedWithAdaptersRepository = false
    var invokedWithAdaptersRepositoryCount = 0
    var invokedWithAdaptersRepositoryParameters: (adaptersRepository: AdaptersRepository, Void)?
    var invokedWithAdaptersRepositoryParametersList = [(adaptersRepository: AdaptersRepository, Void)]()

    override func withAdaptersRepository(_ adaptersRepository: AdaptersRepository) -> Self {
        invokedWithAdaptersRepository = true
        invokedWithAdaptersRepositoryCount += 1
        invokedWithAdaptersRepositoryParameters = (adaptersRepository, ())
        invokedWithAdaptersRepositoryParametersList.append((adaptersRepository, ()))
        return self
    }

    var invokedWithEnvironmentRepository = false
    var invokedWithEnvironmentRepositoryCount = 0
    var invokedWithEnvironmentRepositoryParameters: (environmentRepository: EnvironmentRepository?, Void)?
    var invokedWithEnvironmentRepositoryParametersList = [(environmentRepository: EnvironmentRepository?, Void)]()

    override func withEnvironmentRepository(_ environmentRepository: EnvironmentRepository?) -> Self {
        invokedWithEnvironmentRepository = true
        invokedWithEnvironmentRepositoryCount += 1
        invokedWithEnvironmentRepositoryParameters = (environmentRepository, ())
        invokedWithEnvironmentRepositoryParametersList.append((environmentRepository, ()))
        return self
    }

    var invokedWithExt = false
    var invokedWithExtCount = 0
    var invokedWithExtParameters: (ext: [[String: Any]], Void)?
    var invokedWithExtParametersList = [(ext: [[String: Any]], Void)]()

    override func withExt(_ ext: [String: Any] ...) -> Self {
        invokedWithExt = true
        invokedWithExtCount += 1
        invokedWithExtParameters = (ext, ())
        invokedWithExtParametersList.append((ext, ()))
        return self
    }

    var invokedWithTestMode = false
    var invokedWithTestModeCount = 0
    var invokedWithTestModeParameters: (testMode: Bool, Void)?
    var invokedWithTestModeParametersList = [(testMode: Bool, Void)]()

    override func withTestMode(_ testMode: Bool) -> Self {
        invokedWithTestMode = true
        invokedWithTestModeCount += 1
        invokedWithTestModeParameters = (testMode, ())
        invokedWithTestModeParametersList.append((testMode, ()))
        return self
    }

    var invokedWithImpression = false
    var invokedWithImpressionCount = 0
    var invokedWithImpressionParameters: (impression: Impression, Void)?
    var invokedWithImpressionParametersList = [(impression: Impression, Void)]()

    func withImpression(_ impression: Impression) -> Self {
        invokedWithImpression = true
        invokedWithImpressionCount += 1
        invokedWithImpressionParameters = (impression, ())
        invokedWithImpressionParametersList.append((impression, ()))
        return self
    }

    var invokedWithRoute = false
    var invokedWithRouteCount = 0
    var invokedWithRouteParameters: (route: Route, Void)?
    var invokedWithRouteParametersList = [(route: Route, Void)]()

    func withRoute(_ route: Route) -> Self {
        invokedWithRoute = true
        invokedWithRouteCount += 1
        invokedWithRouteParameters = (route, ())
        invokedWithRouteParametersList.append((route, ()))
        return self
    }

    var invokedWithExternalWinner = false
    var invokedWithExternalWinnerCount = 0
    var invokedWithExternalWinnerParameters: (demandId: String, price: Price)?
    var invokedWithExternalWinnerParametersList = [(demandId: String, price: Price)]()

    func withExternalWinner(demandId: String, price: Price) -> Self {
        invokedWithExternalWinner = true
        invokedWithExternalWinnerCount += 1
        invokedWithExternalWinnerParameters = (demandId, price)
        invokedWithExternalWinnerParametersList.append((demandId, price))
        return self
    }

    var invokedWithAdTypeContext = false
    var invokedWithAdTypeContextCount = 0
    var invokedWithAdTypeContextParameters: (context: Context, Void)?
    var invokedWithAdTypeContextParametersList = [(context: Context, Void)]()

    func withAdTypeContext(_ context: Context) -> Self {
        invokedWithAdTypeContext = true
        invokedWithAdTypeContextCount += 1
        invokedWithAdTypeContextParameters = (context, ())
        invokedWithAdTypeContextParametersList.append((context, ()))
        return self
    }
}
