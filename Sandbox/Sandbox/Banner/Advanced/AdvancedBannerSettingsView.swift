//
//  AdvancedBannerSettingsView.swift
//  Sandbox
//
//  Created by Stas Kochkin on 05.09.2023.
//

import Foundation
import SwiftUI
import Bidon


struct AdvancedBannerSettings: View {
    @ObservedObject var bannerProviderReference = BannerProviderReference.shared
    
    @Binding var format: AdBannerWrapperFormat {
        didSet {
            BannerProviderReference.shared.format = Bidon.BannerFormat(format)
        }
    }
    
    @Binding var isAutorefreshing: Bool
    @Binding var autorefreshInterval: TimeInterval
    
    @State var pricefloor: Price = 0.1
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Banner Format")) {
                    ForEach(AdBannerWrapperFormat.allCases, id: \.rawValue) { format in
                        Button(action: {
                            withAnimation {
                                self.format = format
                            }
                        }) {
                            HStack {
                                Text(format.rawValue.capitalized)
                                Spacer()
                                if self.format == format {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Banner Settings")) {
                    Toggle("Autorefreshing", isOn: $isAutorefreshing)
                    HStack {
                        Text("Refresh interval")
                        Spacer()
                        Text(String(format: "%1.0f", autorefreshInterval) + "s")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("5s")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Slider(
                            value: Binding(
                                get: { autorefreshInterval / 5 },
                                set: { autorefreshInterval = 5 * $0 }
                            ),
                            in: (1...6)
                        )
                        Text("30s")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .disabled(true)
                
                Section(header: Text("Banner Provider")) {
                    NavigationLink(
                        destination: {
                            BannerPositionPickerView()
                        },
                        label: {
                            HStack {
                                Text("Position")
                                Spacer()
                                Text("Unknown")
                                    .foregroundColor(.secondary)
                            }
                        }
                    )
                    
                    Stepper(
                        "Pricefloor: \(pricefloor.pretty)",
                        value: $pricefloor,
                        in: (0.0...100.0),
                        step: 0.1
                    )
                    
                    Button(action: {
                        bannerProviderReference.provider.loadAd(with: pricefloor)
                    }) {
                        HStack {
                            Text("Load")
                            Spacer()
                            if bannerProviderReference.isLoaded {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: bannerProviderReference.provider.show) {
                        HStack {
                            Text("Show")
                            Spacer()
                            if bannerProviderReference.isLoaded {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: bannerProviderReference.provider.hide) {
                        Text("Hide")
                    }
                    .foregroundColor(.primary)
                }
            }
            .listStyle(.automatic)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Advanced")
    }
}
