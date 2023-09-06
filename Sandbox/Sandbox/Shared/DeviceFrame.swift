//
//  DeviceFrame.swift
//  Sandbox
//
//  Created by Stas Kochkin on 06.09.2023.
//

import Foundation
import UIKit


struct DeviceFrame {
    var width: CGFloat
    var height: CGFloat
    
    var size: CGSize {
        CGSize(
            width: width,
            height: height
        )
    }
    
    init(scale: CGFloat) {
        guard let window = UIApplication.shared.topWindow else {
            width = 0
            height = 0
            return
        }
        
        let bounds = window.bounds.inset(by: window.safeAreaInsets)
        
        width = bounds.width * scale
        height = bounds.height * scale
    }
}


fileprivate extension UIApplication {
    var topWindow: UIWindow? {
        return connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .map { $0.windows }
            .reduce([], +)
            .first { $0.isKeyWindow }
    }
}
