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


extension Bidon.GDPRConsentStatus {
    init(_ flag: Bool?) {
        guard let flag = flag else {
            self = .unknown
            return
        }
        self = flag ? .given : .denied
    }
}

extension Bidon.Ad {
    
    var description: String? {
        let dictRepresentation: [String: Any] = [
            "unit_name": adUnit.label,
            "network_name": "Bidon",
            "placement_id": "null",
            "placement_name": "null",
            "revenue": price,
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
        
        if #available(iOS 13.0, *) {
            if let data = try? JSONSerialization.data(withJSONObject: dictRepresentation, options: .withoutEscapingSlashes) {
                let convertedString = String(data: data, encoding: .utf8)
                return convertedString
            }
        } else {
            if let data = try? JSONSerialization.data(withJSONObject: dictRepresentation, options: []) {
                let convertedString = String(data: data, encoding: .utf8)
                return convertedString
            }
        }
        
        return nil
    }
}
