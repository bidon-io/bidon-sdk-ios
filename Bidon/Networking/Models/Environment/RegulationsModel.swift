//
//  RegulationsModel.swift
//  Bidon
//
//  Created by Bidon Team on 30.05.2023.
//

import Foundation


struct RegulationsModel: Encodable {
    var coppa: Bool
    var gdpr: Bool
    var euPrivacyString: String?
    var usPrivacyString: String?
    //    var tcfV1: [String: Any]
    //    var tcfV2: [String: Any]
    var iab: IABModel
    
    struct IABModel: Encodable {
        var tcfV1: [String: Any]
        var tcfV2: [String: Any]
        var usPrivacyString: String?
        
        enum CodingKeys: String, CodingKey {
            case tcfV1
            case tcfV2
            case usPrivacyString = "us_privacy"
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(usPrivacyString, forKey: .usPrivacyString)
            try encodeIfPresented(container: &container, tcf: tcfV1, for: .tcfV1)
            try encodeIfPresented(container: &container, tcf: tcfV2, for: .tcfV2)
        }
        
        private func encodeIfPresented(
            container: inout KeyedEncodingContainer<CodingKeys>,
            tcf: [String: Any],
            for key: CodingKeys
        ) throws {
            guard !tcf.isEmpty else { return }
            
            let data = try JSONSerialization.data(withJSONObject: tcf)
            let string = String(data: data, encoding: .utf8)
            try container.encode(string, forKey: key)
        }
    }
    
    //    enum CodingKeys: String, CodingKey {
    //        case coppa
    //        case gdpr
    //        case euPrivacyString
    //        case usPrivacyString
    //        case tcfV1
    //        case tcfV2
    //    }
    
    init(_ regulations: ExtendedRegulations) {
        self.coppa = regulations.coppaApplies == .yes
        self.gdpr = regulations.gdrpConsent == .given
        self.euPrivacyString = regulations.gdprConsentString
        self.usPrivacyString = regulations.usPrivacyString
        self.iab = IABModel(
            tcfV1: regulations.tcfV1,
            tcfV2: regulations.tcfV2,
            usPrivacyString: regulations.usPrivacyStringIAB
        ) 
    }
    
    //    func encode(to encoder: Encoder) throws {
    //        var container = encoder.container(keyedBy: CodingKeys.self)
    //        try container.encode(self.coppa, forKey: .coppa)
    //        try container.encode(self.gdpr, forKey: .gdpr)
    //        try container.encodeIfPresent(self.euPrivacyString, forKey: .euPrivacyString)
    //        try container.encodeIfPresent(self.usPrivacyString, forKey: .usPrivacyString)
    //
    //        try encodeIfPresented(container: &container, tcf: tcfV1, for: .tcfV1)
    //        try encodeIfPresented(container: &container, tcf: tcfV2, for: .tcfV2)
    //    }
    
    //    private func encodeIfPresented(
    //        container: inout KeyedEncodingContainer<CodingKeys>,
    //        tcf: [String: Any],
    //        for key: CodingKeys
    //    ) throws {
    //        guard !tcf.isEmpty else { return }
    //
    //        let data = try JSONSerialization.data(withJSONObject: tcf)
    //        let string = String(data: data, encoding: .utf8)
    //        try container.encode(string, forKey: key)
    //    }
}
