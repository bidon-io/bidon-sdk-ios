//
//  AdapterIdCodingKey.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


struct DemandIdCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        return nil
    }
    
    init(_ adapter: Adapter) {
        self.stringValue = adapter.demandId
    }
}
