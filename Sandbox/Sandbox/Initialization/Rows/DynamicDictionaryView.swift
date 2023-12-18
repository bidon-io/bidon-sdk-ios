//
//  DynamicDictionaryView.swift
//  Sandbox
//
//  Created by Stas Kochkin on 18.12.2023.
//

import Foundation
import SwiftUI


struct DynamicDictionaryView: View {
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
