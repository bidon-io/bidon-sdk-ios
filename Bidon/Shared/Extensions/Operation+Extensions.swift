//
//  Operation+Extensions.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation



extension Operation {
    func deps<T: Operation>(_ type: T.Type) -> [T] {
        return dependencies.compactMap { $0 as? T }
    }
}
