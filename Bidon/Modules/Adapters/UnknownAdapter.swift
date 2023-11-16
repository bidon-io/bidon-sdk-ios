//
//  UnknownAdapter.swift
//  Bidon
//
//  Created by Bidon Team on 13.03.2023.
//

import Foundation


struct UnknownAdapter: Adapter, Hashable {
    var demandId: String
    var name: String
    var adapterVersion: String
    var sdkVersion: String
    
    init(demandId: String) {
        self.demandId = demandId
        self.name = "Unknown"
        self.adapterVersion = ""
        self.sdkVersion = ""
    }
    
    init() {
        fatalError("UnknownAdapter can't be created through default initializer")
    }
}
