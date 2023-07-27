//
//  BidRequestBuilderMock.swift
//  Tests-Swift
//
//  Created by Bidon Team on 22.06.2023.
//

import Foundation

@testable import Bidon


final class BidRequestBuilderMock: BaseRequestBuilder, BidRequestBuilder {
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
    var stubbedImp: BidRequestImp!

    var imp: BidRequestImp {
        invokedImpGetter = true
        invokedImpGetterCount += 1
        return stubbedImp
    }

    var invokedAdTypeGetter = false
    var invokedAdTypeGetterCount = 0
    var stubbedAdType: AdType!

    var adType: AdType {
        invokedAdTypeGetter = true
        invokedAdTypeGetterCount += 1
        return stubbedAdType
    }

    var invokedAdaptersGetter = false
    var invokedAdaptersGetterCount = 0
    var stubbedAdapters: AdaptersInfo!

    var adapters: AdaptersInfo {
        invokedAdaptersGetter = true
        invokedAdaptersGetterCount += 1
        return stubbedAdapters
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

    var invokedWithBiddingContextEncoders = false
    var invokedWithBiddingContextEncodersCount = 0
    var invokedWithBiddingContextEncodersParameters: (encoders: BiddingContextEncoders, Void)?
    var invokedWithBiddingContextEncodersParametersList = [(encoders: BiddingContextEncoders, Void)]()

    func withBiddingContextEncoders(_ encoders: BiddingContextEncoders) -> Self {
        invokedWithBiddingContextEncoders = true
        invokedWithBiddingContextEncodersCount += 1
        invokedWithBiddingContextEncodersParameters = (encoders, ())
        invokedWithBiddingContextEncodersParametersList.append((encoders, ()))
        return self
    }

    var invokedWithBidfloor = false
    var invokedWithBidfloorCount = 0
    var invokedWithBidfloorParameters: (bidfloor: Price, Void)?
    var invokedWithBidfloorParametersList = [(bidfloor: Price, Void)]()

    func withBidfloor(_ bidfloor: Price) -> Self {
        invokedWithBidfloor = true
        invokedWithBidfloorCount += 1
        invokedWithBidfloorParameters = (bidfloor, ())
        invokedWithBidfloorParametersList.append((bidfloor, ()))
        return self
    }

    var invokedWithAuctionId = false
    var invokedWithAuctionIdCount = 0
    var invokedWithAuctionIdParameters: (auctionId: String, Void)?
    var invokedWithAuctionIdParametersList = [(auctionId: String, Void)]()

    func withAuctionId(_ auctionId: String) -> Self {
        invokedWithAuctionId = true
        invokedWithAuctionIdCount += 1
        invokedWithAuctionIdParameters = (auctionId, ())
        invokedWithAuctionIdParametersList.append((auctionId, ()))
        return self
    }

    var invokedWithRoundId = false
    var invokedWithRoundIdCount = 0
    var invokedWithRoundIdParameters: (roundId: String, Void)?
    var invokedWithRoundIdParametersList = [(roundId: String, Void)]()

    func withRoundId(_ roundId: String) -> Self {
        invokedWithRoundId = true
        invokedWithRoundIdCount += 1
        invokedWithRoundIdParameters = (roundId, ())
        invokedWithRoundIdParametersList.append((roundId, ()))
        return self
    }

    var invokedWithAuctionConfigurationId = false
    var invokedWithAuctionConfigurationIdCount = 0
    var invokedWithAuctionConfigurationIdParameters: (auctionConfigurationId: Int, Void)?
    var invokedWithAuctionConfigurationIdParametersList = [(auctionConfigurationId: Int, Void)]()

    func withAuctionConfigurationId(_ auctionConfigurationId: Int) -> Self {
        invokedWithAuctionConfigurationId = true
        invokedWithAuctionConfigurationIdCount += 1
        invokedWithAuctionConfigurationIdParameters = (auctionConfigurationId, ())
        invokedWithAuctionConfigurationIdParametersList.append((auctionConfigurationId, ()))
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

    var invokedWithAdapters = false
    var invokedWithAdaptersCount = 0
    var invokedWithAdaptersParameters: (adapters: [Adapter], Void)?
    var invokedWithAdaptersParametersList = [(adapters: [Adapter], Void)]()

    func withAdapters(_ adapters: [Adapter]) -> Self {
        invokedWithAdapters = true
        invokedWithAdaptersCount += 1
        invokedWithAdaptersParameters = (adapters, ())
        invokedWithAdaptersParametersList.append((adapters, ()))
        return self
    }
    
    func biddingToken(for demandId: String) -> String? {
        let encoder = invokedWithBiddingContextEncodersParameters?.encoders[demandId] as? GenericBiddingContextEncoder<SomeToken>
        return encoder?.context.token
    }
    
    var demandsCount: Int {
        invokedWithBiddingContextEncodersParameters?.encoders.count ?? 0
    }
}
