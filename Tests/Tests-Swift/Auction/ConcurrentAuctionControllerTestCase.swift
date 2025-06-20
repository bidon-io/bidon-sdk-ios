//
//  Tests_Swift.swift
//  Tests-Swift
//
//  Created by Bidon Team on 22.06.2023.
//

import XCTest

@testable import Bidon


//typealias TestAuctionResult = Result<BidModel<DemandProviderMock>, SdkError>
//
//
//final class TestConcurrentAuctionControllerBuilder: BaseConcurrentAuctionControllerBuilder<AdTypeContextMock> {
//    override func adapters() -> [AnyDemandSourceAdapter<DemandProviderMock>] {
//        let adapters: [AdapterMock] = adaptersRepository.all()
//        return adapters.map {
//            AnyDemandSourceAdapter(
//                adapter: $0,
//                provider: $0.stubbedProvider
//            )
//        }
//    }
//}
//
//
//final class ConcurrentAuctionControllerTestCase: XCTestCase {
//    var contextMock: AdTypeContextMock!
//    var networkManagerMock: NetworkManagerMockProxy!
//    
//    var adaptersRepository: AdaptersRepository!
//    var controller: ConcurrentAuctionController<AdTypeContextMock>!
//    var auctionObserver: BaseAuctionObserver!
//    var adRevenueObserver: AdRevenueObserver!
//    
//    var auctionConfiguration: AuctionConfiguration!
//    var adType: AdType!
//    var pricefloor: Price!
//    
//    override func setUp() {
//        adType = .interstitial
//        pricefloor = Double.random(in: 9.99...999.99)
//        auctionConfiguration = AuctionConfiguration(
//            auctionId: UUID().uuidString,
//            auctionConfigurationUid: UUID().uuidString,
//            isExternalNotificationsEnabled: false
//        )
//        
//        contextMock = AdTypeContextMock()
//        contextMock.stubbedAdType = adType
//           
//        networkManagerMock = NetworkManagerMockProxy()
//        NetworkManagerInjectionKey.currentValue = networkManagerMock
//        
//        adaptersRepository = AdaptersRepository()
//        adRevenueObserver = BaseAdRevenueObserver()
//        auctionObserver = BaseAuctionObserver(
//            configuration: auctionConfiguration,
//            adType: .interstitial
//        )
//    }
//    
//    override func tearDown() {
//        controller = nil
//        pricefloor = nil
//        auctionConfiguration = nil
//        contextMock = nil
//        adaptersRepository = nil
//        adRevenueObserver = nil
//        auctionObserver = nil
//        
//        NetworkManagerInjectionKey.currentValue = PersistentNetworkManager.shared
//    }
//    
//    final func controller(
//        rounds: [AuctionRoundMock],
//        adUnits: [AdUnitModel]
//    ) -> ConcurrentAuctionController<AdTypeContextMock> {
//        let adUnitProvider = DefaultAdUnitProvider(adUnits: adUnits)
//        
//        return ConcurrentAuctionController { (builder: TestConcurrentAuctionControllerBuilder) in
//            builder.withRounds(rounds)
//            builder.withContext(contextMock)
//            builder.withAdUnitProvider(adUnitProvider)
//            builder.withAuctionObserver(auctionObserver)
//            builder.withPricefloor(pricefloor)
//            builder.withAdaptersRepository(adaptersRepository)
//            builder.withAdRevenueObserver(adRevenueObserver)
//            builder.withAuctionConfiguration(auctionConfiguration)
//        }
//    }
//    
//    final func stubBidRequest(
//        _ request: BidRequest,
//        assert: ((BidRequestBuilderMock) -> ())? = nil
//    ) {
//        contextMock.stubbedBidRequest = { build in
//            let builder = BidRequestBuilderMock()
//            builder.stubbedAdType = self.contextMock.stubbedAdType
//            build(builder)
//            if let assert = assert {
//                assert(builder)
//            }
//            
//            return request
//        }
//    }
//    
//    final func stubBidResponseSuccess(
//        request: BidRequest,
//        response: BidRequest.ResponseBody
//    ) {
//        networkManagerMock.stub(request, result: .success(response))
//    }
//    
//    final func stubBidResponseFailure(
//        request: BidRequest,
//        error: HTTPTask.HTTPError
//    ) {
//        networkManagerMock.stub(request, result: .failure(error))
//    }
//
//    func testAuctionFailureWithEmptyDemand() {
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        
//        var result: TestAuctionResult!
//        
//        let rounds = [
//            AuctionRoundMock(
//                id: "round_1",
//                timeout: timeout,
//                demands: [""],
//                bidding: [""]
//            )
//        ]
//        
//        let adUnits: [AdUnitModel] = []
//        
//        controller = controller(
//            rounds: rounds,
//            adUnits: adUnits
//        )
//        
//        controller.load {
//            result = $0
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
//    
//        let report = auctionObserver.report
//        
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//        XCTAssertEqual(report.result.status, .fail)
//        
//        XCTAssertEqual(report.rounds.count, 1)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, "round_1")
//        XCTAssertEqual(report.rounds[0].demands.count, 1)
//        XCTAssertEqual(report.rounds[0].demands[0].demandId, "")
//        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "UNKNOWN_ADAPTER")
//    }
//}
//
//
//extension TestAuctionResult {
//    var isSuccess: Bool {
//        switch self {
//        case .success: return true
//        case .failure: return false
//        }
//    }
//}
//
//
//extension AuctionRoundReport {
//    var sortedDemands: [AuctionDemandReportType] {
//        return demands.sorted { first, second in
//            let firstId = first.demandId
//            let secondId = second.demandId 
//            return firstId < secondId
//        }
//    }
//}
