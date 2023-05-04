//
//  UIApplication+Extensions.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 05.07.2022.
//

import Foundation
import UIKit


public extension UIApplication {
    var bd: DSL { .init(application: self) }
    
    struct DSL {
        fileprivate let application: UIApplication
        
        fileprivate init(application: UIApplication) {
            self.application = application
        }
        
        public var window: UIWindow? {
            return windows.first { $0.isKeyWindow }
        }
        
        public var windows: [UIWindow] {
            if #available(iOS 13.0, *) {
                return application
                    .connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .compactMap { $0 as? UIWindowScene }
                    .map { $0.windows }
                    .reduce([], +)
            } else {
                return application.windows
            }
        }
        
        public var topViewcontroller: UIViewController? {
            return window?.topPresentedViewController()
        }
        
        public var isLandscape: Bool {
            if #available(iOS 13, *) {
                return window?.windowScene?.interfaceOrientation.isLandscape ?? false
            } else {
                return application.statusBarOrientation.isLandscape
            }
        }
    }
}


internal extension UIWindow {
    func topPresentedViewController() -> UIViewController? {
        var topViewController = rootViewController
        while (true) {
            if topViewController?.presentedViewController != nil {
                topViewController = topViewController?.presentedViewController;
            } else if let navigationViewController = topViewController as? UINavigationController  {
                topViewController = navigationViewController.topViewController;
            } else if let tabBarViewController = topViewController as? UITabBarController {
                topViewController = tabBarViewController.selectedViewController;
            } else {
                break;
            }
        }
        return topViewController;
    }
}
