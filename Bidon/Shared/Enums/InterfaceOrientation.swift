//
//  InterfaceOrientation.swift
//  Bidon
//
//  Created by Bidon Team on 31.05.2023.
//

import Foundation
import UIKit


enum InterfaceOrientation: String, Codable {
    case portrait
    case landscape
}


extension InterfaceOrientation {
    init(_ isLandscape: Bool) {
        self = isLandscape ? .landscape : .portrait
    }

    static var current: InterfaceOrientation {
        let isLandscape = DispatchQueue.bd.blocking { UIApplication.shared.bd.isLandscape }
        return InterfaceOrientation(isLandscape)
    }
}


extension InterfaceOrientation {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue.uppercased())
    }
}
