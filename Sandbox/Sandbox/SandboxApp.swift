//
//  SandboxApp.swift
//  Sandbox
//
//  Created by Bidon Team on 04.08.2022.
//

import SwiftUI
import Combine
import Bidon


@main
struct SandboxApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


final class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        AdServiceProvider.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        return true
    }
}
