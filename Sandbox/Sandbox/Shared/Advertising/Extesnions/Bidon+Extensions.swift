//
//  Bidon+Extensions.swift
//  Sandbox
//
//  Created by Bidon Team on 15.06.2023.
//

import Foundation
import Bidon


extension Bidon.Logger.Level {
    init(_ level: LogLevel) {
        switch level {
        case .verbose: self = .verbose
        case .debug: self = .debug
        case .info: self = .info
        case .warning: self = .warning
        case .error: self = .error
        case .off: self = .off
        }
    }
}


extension Bidon.Gender {
    init(_ gender: Gender) {
        switch gender {
        case .male: self = .male
        case .female: self = .female
        case .other: self = .other
        }
    }
}


extension Bidon.COPPAAppliesStatus {
    init(_ flag: Bool?) {
        guard let flag = flag else {
            self = .unknown
            return
        }
        self = flag ? .yes : .no
    }
}


extension Bidon.GDPRAppliesStatus {
    init(_ flag: Bool?) {
        guard let flag = flag else {
            self = .unknown
            return
        }
        self = flag ? .applies : .doesNotApply
    }
}

extension Bidon.Ad {

    func description(with revenue: AdRevenue? = nil) -> String? {
        let dictRepresentation: [String: Any] = [
            "unit_name": adUnit.label,
            "network_name": "Bidon",
            "placement_id": "null",
            "placement_name": "null",
            "revenue": revenue?.revenue ?? price,
            "currency": currencyCode ?? "USD",
            "precision": adUnit.bidType == .cpm ? "estimated" : "exact",
            "demand_source": adUnit.demandId,
            "ext": [
                "network_name": adUnit.demandId,
                "dsp_name": networkName,
                "ad_unit_id": adUnit.uid,
                "credentials": adUnit.extras
            ]
        ]

        return String(describing: dictRepresentation)
    }
}
