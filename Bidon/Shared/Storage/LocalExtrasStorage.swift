//
//  LocalExtrasStorage.swift
//  Adjust
//
//  Created by Евгения Григорович on 09/06/2025.
//

import Foundation

final class LocalExtrasStorage {
    static let storedLocalExtrasKey = "stored_local_extras"
    static func fetchLocalExtras() -> [String: [String: String?]]? {
        return UserDefaults.standard.dictionary(forKey: storedLocalExtrasKey) as? [String: [String: String?]]
    }
}
