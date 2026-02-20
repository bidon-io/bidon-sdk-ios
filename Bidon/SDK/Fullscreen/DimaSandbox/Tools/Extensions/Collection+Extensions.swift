//
//  Collection+Extensions.swift
//  Bidon
//
//  Created by Dzmitry on 19/02/2026.
//

import Foundation

extension Collection {
    func sorted<T: Comparable>(
        by keyPath: KeyPath<Element, T>,
        areInIncreasingOrder: (T, T) -> Bool = { $0 < $1 }
    ) -> [Element] {
        self.sorted { areInIncreasingOrder($0[keyPath: keyPath], $1[keyPath: keyPath]) }
    }
}
