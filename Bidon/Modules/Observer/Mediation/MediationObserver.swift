//
//  MediationObserver.swift
//  Bidon
//
//  Created by Bidon Team on 05.09.2022.
//

import Foundation


protocol MediationReportProvider {
    associatedtype MediationAttemptReportType: MediationAttemptReport
    
    var report: MediationAttemptReportType { get }
}


protocol MediationObserver: AnyObject {
    func log<EventType: MediationEvent>(_ event: EventType)
}


typealias AnyMediationObserver = any MediationObserver & MediationReportProvider
