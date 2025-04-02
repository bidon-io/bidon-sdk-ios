//
//  MediationObserver.swift
//  Bidon
//
//  Created by Bidon Team on 05.09.2022.
//

import Foundation


protocol AuctionReportProvider {
    associatedtype AuctionReportType: AuctionReport
    
    var report: AuctionReportType { get }
}


protocol AuctionObserver: AnyObject {
    func log<EventType: AuctionEvent>(_ event: EventType)
}


typealias AnyAuctionObserver = any AuctionObserver & AuctionReportProvider
