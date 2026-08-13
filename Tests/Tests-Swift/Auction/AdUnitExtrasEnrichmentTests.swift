//
//  AdUnitExtrasEnrichmentTests.swift
//  Tests-Swift
//
//  Created by Bidon Team on 13.08.2026.
//

import Testing
import Foundation

@testable import Bidon


@Suite
struct AdUnitExtrasEnrichmentTests {

    private final class ExtrasProvidingDemandAdMock: NSObject, DemandAd, DemandAdExtrasProvider {
        let id: String = UUID().uuidString
        let additionalAdUnitExtras: [String: BidonDecodable]?

        init(additionalAdUnitExtras: [String: BidonDecodable]?) {
            self.additionalAdUnitExtras = additionalAdUnitExtras
            super.init()
        }
    }

    private final class PlainDemandAdMock: NSObject, DemandAd {
        let id: String = UUID().uuidString
    }

    @Test
    func relaysAllAdditionalExtrasIntoAdUnitExt() throws {
        let adUnit = try makeAdUnit(ext: ["payload": "payload123"])
        let ad = ExtrasProvidingDemandAdMock(additionalAdUnitExtras: [
            "custom_param": BidonDecodable(value: "custom123"),
            "another_param": BidonDecodable(value: "another123")
        ])

        let enriched = adUnit.enriched(with: ad)

        #expect(enriched.extrasDictionary?["custom_param"]?.value as? String == "custom123")
        #expect(enriched.extrasDictionary?["another_param"]?.value as? String == "another123")
        #expect(enriched.extrasDictionary?["payload"]?.value as? String == "payload123")
    }

    @Test
    func additionalExtrasOverrideServerExtOnKeyCollision() throws {
        let adUnit = try makeAdUnit(ext: ["payload": "payload123"])
        let ad = ExtrasProvidingDemandAdMock(additionalAdUnitExtras: [
            "payload": BidonDecodable(value: "overridden")
        ])

        let enriched = adUnit.enriched(with: ad)

        #expect(enriched.extrasDictionary?.count == 1)
        #expect(enriched.extrasDictionary?["payload"]?.value as? String == "overridden")
    }

    @Test
    func keepsAdUnitExtUntouchedWhenAdCarriesNoAdditionalExtras() throws {
        let adUnit = try makeAdUnit(ext: ["payload": "payload123"])

        let enrichedWithNil = adUnit.enriched(
            with: ExtrasProvidingDemandAdMock(additionalAdUnitExtras: nil)
        )
        let enrichedWithEmpty = adUnit.enriched(
            with: ExtrasProvidingDemandAdMock(additionalAdUnitExtras: [:])
        )
        let enrichedWithPlainAd = adUnit.enriched(with: PlainDemandAdMock())

        #expect(enrichedWithNil.extrasDictionary?.count == 1)
        #expect(enrichedWithNil.extrasDictionary?["payload"]?.value as? String == "payload123")
        #expect(enrichedWithEmpty.extrasDictionary?.count == 1)
        #expect(enrichedWithPlainAd.extrasDictionary?.count == 1)
    }

    @Test
    func relaysAdditionalExtrasWhenAdUnitCameWithoutExt() throws {
        let adUnit = try makeAdUnit(ext: nil)
        let ad = ExtrasProvidingDemandAdMock(additionalAdUnitExtras: [
            "custom_param": BidonDecodable(value: "custom123")
        ])

        let enriched = adUnit.enriched(with: ad)

        #expect(enriched.extrasDictionary?.count == 1)
        #expect(enriched.extrasDictionary?["custom_param"]?.value as? String == "custom123")
    }

    @Test
    func relaysAdditionalExtrasIntoObservationEntryCapturedBeforeLoad() throws {
        let adUnit = try makeAdUnit(ext: ["payload": "payload123"])
        let ad = ExtrasProvidingDemandAdMock(additionalAdUnitExtras: [
            "custom_param": BidonDecodable(value: "custom123")
        ])

        var observation = DemandObservation(tokens: [])
        observation.willLoadAdUnit(adUnit)

        let bid = BidModel<Void>(
            id: UUID().uuidString,
            impressionId: UUID().uuidString,
            adType: .interstitial,
            adUnit: adUnit.enriched(with: ad),
            price: 2.75,
            ad: ad,
            provider: (),
            roundPricefloor: 2.75,
            auctionConfiguration: makeAuctionConfiguration()
        )
        observation.didReceiveClientBid(bid)

        let entry = try #require(observation.entries.first)
        #expect(entry.adUnit?.extrasDictionary?["custom_param"]?.value as? String == "custom123")
        #expect(entry.adUnit?.extrasDictionary?["payload"]?.value as? String == "payload123")
    }

    private func makeAdUnit(ext: [String: Any]?) throws -> AdUnitModel {
        var json: [String: Any] = [
            "demandId": "bidmachine",
            "uid": "uid123",
            "bidType": "RTB",
            "label": "label123",
            "pricefloor": 2.75,
            "timeout": 5000
        ]
        if let ext {
            json["ext"] = ext
        }

        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(AdUnitModel.self, from: data)
    }

    private func makeAuctionConfiguration() -> AuctionConfiguration {
        AuctionConfiguration(
            auctionId: UUID().uuidString,
            auctionConfigurationUid: "uid123",
            auctionConfigurationId: 1,
            adUnits: [],
            segment: nil,
            token: nil,
            pricefloor: 2.75,
            auctionTimeout: 5000,
            tokens: [],
            isExternalNotificationsEnabled: false
        )
    }
}
