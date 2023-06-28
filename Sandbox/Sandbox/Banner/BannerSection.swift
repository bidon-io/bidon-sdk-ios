//
//  BannerSection.swift
//  Sandbox
//
//  Created by Bidon Team on 29.08.2022.
//

import Foundation
import SwiftUI
import Bidon


struct BannerAdSection: View {
    @EnvironmentObject var vm: BannerSectionViewModel
    
    var body: some View {
        Group {
            Section(header: Text("Banner")) {
                Stepper(
                    "Pricefloor: \(vm.pricefloor.pretty)",
                    value: $vm.pricefloor,
                    in: (0.0...100.0),
                    step: 0.1
                )
                
                Button(action: {
                    withAnimation {
                        vm.isLoading.toggle()
                    }
                }) {
                    HStack {
                        Text(vm.isLoading ? "Loading...": "Load")
                            .foregroundColor(!vm.isPresented || vm.isLoading ? .secondary : .primary)
                        Spacer()
                        if vm.isLoading {
                            ProgressView()
                        }
                    }
                }
                .adContextMenu(
                    vm.ad,
                    onWin: vm.notify(win:),
                    onLoss: vm.notify(loss:)
                )
                .disabled(!vm.isPresented || vm.isLoading)
                
                Button(action: {
                    withAnimation {
                        vm.isPresented.toggle()
                    }
                }) {
                    HStack {
                        Text(vm.isPresented ? "Hide": "Present")
                        Spacer()
                    }
                }
                
                NavigationLink("Events", destination: AdEventsList(events: vm.events))
            }
            
            Section(header: Text("Banner Format")) {
                ForEach(AdBannerWrapperFormat.allCases, id: \.rawValue) { format in
                    Button(action: {
                        withAnimation {
                            vm.format = format
                        }
                    }) {
                        HStack {
                            Text(format.rawValue.capitalized)
                            Spacer()
                            if vm.format == format {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Banner Settings")) {
                Toggle("Autorefreshing", isOn: $vm.isAutorefreshing)
                HStack {
                    Text("Refresh interval")
                    Spacer()
                    Text(String(format: "%1.0f", vm.autorefreshInterval) + "s")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("5s")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Slider(
                        value: Binding(
                            get: { vm.autorefreshInterval / 5 },
                            set: { vm.autorefreshInterval = 5 * $0 }
                        ),
                        in: (1...6)
                    )
                    
                    Text("30s")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .disabled(true)
        }
        .foregroundColor(.primary)
    }
}


extension BannerFormat: CaseIterable {
    public static var allCases: [BannerFormat] = [.adaptive, .banner, .leaderboard, .mrec]
}

