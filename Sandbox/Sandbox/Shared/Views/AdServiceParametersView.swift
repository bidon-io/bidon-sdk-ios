//
//  AdServiceParametersView.swift
//  Sandbox
//
//  Created by Bidon Team on 15.06.2023.
//

import Foundation
import SwiftUI
import FBSDKLoginKit


struct AdServiceParametersView: View {
    @ObservedObject var vm: AdServiceParametersViewModel
    
    init(_ parameters: AdServiceParameters) {
        vm = AdServiceParametersViewModel(parameters)
    }
    
    var body: some View {
        VStack {
            List {
                Section {
                    LogLevelView(logLevel: $vm.logLevel)
                }
                
                Section(header: Text("Regulations")) {
                    Toggle("GDPR", isOn: $vm.gdprApplies)
                    Toggle("COPPA", isOn: $vm.coppaApplies)
                    CMPRow()
                }
                
                Section(header: Text("Regulations")) {
                    TextField("GDPR iAB Formatted String", text: $vm.gdprConsentString)
                    TextField("CCPA iAB Formatted String", text: $vm.usPrivacyString)
        
                }
                .keyboardType(.asciiCapable)
                .autocorrectionDisabled()
                .textCase(.uppercase)
                
                Section(header: Text("User gender")) {
                    GenderPickerRow(gender: $vm.gender)
                }
                
                Section(header: Text("User age")) {
                    Stepper("\(vm.age) years", value: $vm.age, in: (0...100))
                }
                
                Section(header: Text("Game Level")) {
                    Stepper("Level #\(vm.level)", value: $vm.level, in: (0...100))
                }
                
                Section(header: Text("In-App purchase")) {
                    Toggle("Paid app", isOn: $vm.isPaid)
                    Stepper(
                        "Spent \(vm.totalAmount)$",
                        value: $vm.totalAmount,
                        in: (0.0...100.0),
                        step: 9.99
                    )
                }
                
                Section(header: Text("Login with Meta")) {
                    Button(action: vm.handleLoginPress) {
                        HStack {
                            Text(vm.isLoggedIn == true ? "Log Out" : vm.isLoggedIn == false ? "Log In" : "Processing")
                            Spacer()
                            if let _ = vm.isLoggedIn {
                                Image(systemName: "chevron.right")
                                    .imageScale(.small)
                                    .foregroundColor(.secondary)
                            } else {
                                ProgressView()
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section {
                    NavigationLink(
                        "Extras",
                        destination:
                            DynamicDictionaryView(
                                dictionary: $vm.extras
                            )
                            .navigationTitle("Extras")
                    )
                    NavigationLink(
                        "Custom Attributes",
                        destination:
                            DynamicDictionaryView(
                                dictionary: $vm.customAttributes
                            )
                            .navigationTitle("Custom Attributes")
                    )
                }
            }
            .listStyle(.automatic)
        }
        .navigationTitle("Advanced")
    }
}
    
final class AdServiceParametersViewModel: ObservableObject {
    let parameters: AdServiceParameters
    
    @Published var logLevel: LogLevel {
        didSet { parameters.logLevel = logLevel }
    }
    
    @Published var gender: Gender {
        didSet { parameters.userGender = gender }
    }
    
    @Published var age: Int {
        didSet { parameters.userAge = age }
    }
    
    @Published var level: Int {
        didSet { parameters.gameLevel = level }
    }
    
    @Published var isPaid: Bool {
        didSet { parameters.isPaidApp = isPaid }
    }
    
    @Published var totalAmount: Double {
        didSet { parameters.inAppAmount = totalAmount }
    }
    
    @Published var extras: [String: AnyHashable] {
        didSet { parameters.extras = extras }
    }
    
    @Published var customAttributes: [String: AnyHashable] {
        didSet { parameters.customAttributes = customAttributes }
    }
    
    @Published var coppaApplies: Bool {
        didSet { parameters.coppaApplies = coppaApplies }
    }
    
    @Published var gdprApplies: Bool {
        didSet { parameters.gdprApplies = coppaApplies }
    }
    
    @Published var gdprConsentString: String {
        didSet { parameters.gdprConsentString = gdprConsentString }
    }
    
    @Published var usPrivacyString: String {
        didSet { parameters.usPrivacyString = usPrivacyString }
    }
    
    @Published var isLoggedIn: Bool? = AccessToken.current != nil && AccessToken.current?.isExpired == false
    
    let loginManager = LoginManager()
        
    init(_ parameters: AdServiceParameters) {
        self.parameters = parameters
        self.logLevel = parameters.logLevel
        self.gender = parameters.userGender ?? .other
        self.age = parameters.userAge ?? 0
        self.level = parameters.gameLevel ?? 0
        self.isPaid = parameters.isPaidApp
        self.totalAmount = parameters.inAppAmount
        self.extras = parameters.extras
        self.customAttributes = parameters.customAttributes
        self.coppaApplies = parameters.coppaApplies ?? false
        self.gdprApplies = parameters.gdprApplies ?? false
        self.gdprConsentString = parameters.gdprConsentString ?? ""
        self.usPrivacyString = parameters.usPrivacyString ?? ""
    }
    
    
    func handleLoginPress() {
        guard let isLoggedIn = isLoggedIn else { return }
        guard !isLoggedIn else {
            loginManager.logOut()
            self.isLoggedIn = false
            return
        }
        
        self.isLoggedIn = nil
        loginManager.logIn(
            permissions: ["public_profile", "email"],
            from: nil
        ) { [weak self] _, _ in
            self?.isLoggedIn = AccessToken.current != nil && AccessToken.current?.isExpired == false
        }
    }
}
