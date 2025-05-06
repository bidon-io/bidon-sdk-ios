//
//  MediationError+GADErrorCode.swift
//  BidonAdapterGoogleMobileAds
//
//  Created by Bidon Team on 07.09.2022.
//

import Foundation
import Bidon
import GoogleMobileAds


extension MediationError {
    init(gadError: Error?) {
        guard
            let gadError = gadError as? NSError,
            let code = GADErrorCode(rawValue: gadError.code)
        else {
            self = .unspecifiedException("Mapping Error")
            return
        }
        
        switch code {
        case .noFill: self = .noFill(nil)
        case .networkError: self = .networkError
        case .invalidRequest, .invalidArgument: self = .incorrectAdUnitId
        case .timeout: self = .networkError
        default: self = .unspecifiedException("Unknown Error")
        }
    }
}
