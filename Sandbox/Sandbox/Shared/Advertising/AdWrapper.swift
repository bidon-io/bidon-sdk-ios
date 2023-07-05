//
//  AppodealAdWrapper.swift
//  Sandbox
//
//  Created by Bidon Team on 15.02.2023.
//

import Foundation
import Combine
import SwiftUI
import Appodeal
import Bidon


protocol AdWrapper {
    var adEventSubject: PassthroughSubject<AdEventModel, Never> { get }
    var adSubject: PassthroughSubject<Ad?, Never> { get }
    var adType: AdType { get }
}


protocol FullscreenAdWrapper: AdWrapper {
    var isReady: Bool { get }
    
    func show() async throws
    func load(pricefloor: Double) async throws
    func notify(win ad: Ad)
    func notify(loss ad: Ad)
}


extension AdWrapper {
    func send(
        event title: String,
        detail: String,
        bage: String,
        color: Color
    ) {
        let adEvent = AdEventModel(
            date: Date(),
            adType: adType,
            title: title,
            subtitle: detail,
            bage: bage,
            color: color
        )
        
        adEventSubject.send(adEvent)
    }
}
