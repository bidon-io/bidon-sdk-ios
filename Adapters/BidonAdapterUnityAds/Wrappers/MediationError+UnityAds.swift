//
//  MediationError+UnityAdsLoadError.swift
//  BidonAdapterUnityAds
//
//  Created by Bidon Team on 02.03.2023.
//

import Foundation
import UnityAds
import Bidon


extension MediationError {
    init(_ error: any UnityAdsError) {
        self = .unspecifiedException(error.message)
    }
}
