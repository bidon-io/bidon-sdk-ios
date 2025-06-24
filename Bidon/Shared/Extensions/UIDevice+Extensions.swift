//
//  UIDevice+Extensions.swift
//  Bidon
//
//  Created by Bidon Team on 09.09.2022.
//

import Foundation
import UIKit


public extension UIDevice {
    static var bd: DSL = DSL()

    struct DSL {
        @MainThreadComputable(UIDevice.current.userInterfaceIdiom == .phone)
        public var isPhone: Bool
    }
}
