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
                }
                
                Section(header: Text("GDPR Consent String")) {
                    TextField("IAB Formatted String", text: $vm.gdprConsentString)
                        .keyboardType(.asciiCapable)
                        .autocorrectionDisabled()
                        .textCase(.uppercase)
                }
                
                Section(header: Text("US Privacy String")) {
                    TextField("IAB Formatted String", text: $vm.usPrivacyString)
                        .keyboardType(.asciiCapable)
                        .autocorrectionDisabled()
                        .textCase(.uppercase)
                }
                
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

    
fileprivate struct GenderPickerRow: View {
    @Binding var gender: Gender
    
    var body: some View {
        ForEach(Gender.allCases, id: \.rawValue) { option in
            Button(action: {
                withAnimation {
                    gender = option
                }
            }
            ) {
                HStack {
                    Text(option.rawValue.capitalized)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if option == gender {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                        
                    }
                }
            }
        }
    }
}


fileprivate struct DynamicDictionaryView: View {
    @Binding var dictionary: [String: AnyHashable]
    
    @State var isAddingEntry: Bool = false
    
    private var data: [(key: String, value: String)] {
        dictionary
            .compactMapValues { String(describing: $0) }
            .sorted(by: >)
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(data, id: \.key) { key, value in
                    HStack {
                        Text(key)
                        Spacer()
                        Text(value).font(.caption)
                    }
                }
                .onDelete { indexes in
                    indexes
                        .map { data[$0].key }
                        .forEach { dictionary[$0] = nil }
                }
            }
            .toolbar { EditButton() }
            
            Button(action: {
                isAddingEntry.toggle()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor)
                    HStack {
                        Image(systemName: "plus")
                        Text("Add entry")
                            .bold()
                    }
                    .foregroundColor(.white)
                }
                .frame(height: 44)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .sheet(isPresented: $isAddingEntry) {
            AddEntryView(
                isPresented: $isAddingEntry,
                dictionary: $dictionary
            )
        }
    }
    
    private struct AddEntryView: View {
        enum ValueType: String {
            case string
            case bool
            case int
        }
    
        @Binding var isPresented: Bool
        @Binding var dictionary: [String: AnyHashable]
        
        @State var key: String = ""
        @State var rawValue: String = ""
        @State var valueType: ValueType = .string {
            didSet { rawValue = "" }
        }
        
        var body: some View {
            VStack {
                VStack(alignment: .leading) {
                    Text("Key".uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Key", text: $key)
                        .keyboardType(.asciiCapable)
                }
                .padding(.top, 32)
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Value type".uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Value type", selection: $valueType.animation()) {
                        Text("String").tag(ValueType.string)
                        Text("Integer").tag(ValueType.int)
                        Text("Boolean").tag(ValueType.bool)
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Value".uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    switch valueType {
                    case .string:
                        TextField("Value", text: $rawValue)
                            .keyboardType(.asciiCapable)
                    case .int:
                        TextField("Value", text: $rawValue)
                            .keyboardType(.decimalPad)
                    case .bool:
                        Toggle(
                            rawValue == "1" ? "True" : "False",
                            isOn: Binding(
                                get: { rawValue == "1" },
                                set: { rawValue = $0 ? "1" : "0" }
                            )
                        )
                    }
                }
                .transition(.slide)
                
                Spacer()
                Button(action: addEntry) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(key.isEmpty || rawValue.isEmpty ? Color.gray : Color.accentColor)
                        HStack {
                            Image(systemName: "plus")
                            Text("Add entry")
                                .bold()
                        }
                        .foregroundColor(.white)
                    }
                    .frame(height: 44)
                    .disabled(key.isEmpty || rawValue.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .autocapitalization(.none)
            .textFieldStyle(.roundedBorder)
            .padding()
            .background(
                Color(UIColor.tertiarySystemBackground)
                    .edgesIgnoringSafeArea(.all)
            )
        }
        
        func addEntry() {
            let value: AnyHashable
            
            switch valueType {
            case .string:
                value = rawValue
            case .int:
                value = Int(rawValue) ?? 0
            case .bool:
                value = rawValue == "1"
            }
            
            dictionary[key] = value
            isPresented = false
        }
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
